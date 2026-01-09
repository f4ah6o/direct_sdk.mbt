// Basic usage example for Direct SDK
// This example demonstrates how to:
// 1. Create a client with an access token
// 2. Connect to the Direct API
// 3. Get current user information
// 4. Get talks/rooms
// 5. Send a text message
// 6. Handle incoming messages

// Note: This is a simplified example for documentation purposes.
// In a real application, you would handle async operations properly.

// === 1. Create a client ===
// The client requires an access token from Direct4B
fn create_client_example() -> @rpc_client.Client {
  let token = "your-access-token-here"
  let client = @rpc_client.new_client_with_token(token)
  client
}

// === 2. Connect to the API ===
// cfg(target="native")
pub async fn connect_example(client : @rpc_client.Client) -> Result[Unit, @errors.DirectError] {
  match await @rpc_client.connect(client) {
    | Ok(_) => {
      println("Connected to Direct API")
      Ok(())
    }
    | Err(e) => {
      println("Connection failed: \${@errors.direct_error_to_string(e)}")
      Err(e)
    }
  }
}

// === 3. Get current user information ===
// cfg(target="native")
pub async fn get_me_example(client : @rpc_client.Client) -> Result[Unit, @errors.DirectError] {
  match await @api_users.get_me(client) {
    | Ok(user) => {
      println("User: \${user.display_name}")
      println("Email: \${user.email}")
      Ok(())
    }
    | Err(e) => {
      println("Failed to get user info: \${@errors.direct_error_to_string(e)}")
      Err(e)
    }
  }
}

// === 4. Get talks/rooms ===
// cfg(target="native")
pub async fn get_talks_example(client : @rpc_client.Client) -> Result[Unit, @errors.DirectError] {
  match await @api_talks.get_talks(client) {
    | Ok(talks) => {
      for talk in talks {
        println("Talk: \${talk.name}")
      }
      Ok(())
    }
    | Err(e) => {
      println("Failed to get talks: \${@errors.direct_error_to_string(e)}")
      Err(e)
    }
  }
}

// === 5. Send a text message ===
// cfg(target="native")
pub async fn send_message_example(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  talk_id : @types.ID,
  text : String
) -> Result[Unit, @errors.DirectError] {
  let content = @types.JsonObject(Map::from_array([
    ("text", @types.JsonString(text))
  ]))

  let params = [
    @types.id_to_json(talk_id),
    @types.JsonNumber(@types.msg_type_to_wire(@types.MsgTypeText).to_float()),
    content,
  ]

  match await @rpc_client.call(client, @constants.METHOD_CREATE_MESSAGE, params) {
    | Ok(_) => {
      println("Message sent: \${text}")
      Ok(())
    }
    | Err(e) => {
      println("Failed to send message: \${@errors.direct_error_to_string(e)}")
      Err(e)
    }
  }
}

// === 6. Handle incoming messages ===
pub fn setup_message_handler_example(client : @rpc_client.Client) -> Unit {
  // Register a handler for all messages
  @rpc_client.on_message(client, fn(msg) {
    println("Received message from: \${msg.user_id}")
    println("Content: \${msg.text}")
  })

  // Register a handler for specific events
  @rpc_client.on(client, @constants.EVENT_NOTIFY_CREATE_MESSAGE, fn(data) {
    println("New message notification: \${data}")
  })

  ()
}

// === Complete example ===
// cfg(target="native")
pub async fn main_example() -> Result[Unit, @errors.DirectError] {
  // Create client
  let client = create_client_example()

  // Connect
  await connect_example(client)?

  // Get user info
  await get_me_example(client)?

  // Get talks
  await get_talks_example(client)?

  // Setup message handler
  setup_message_handler_example(client)

  // Send a message (replace with actual IDs)
  // await send_message_example(client, @types.IDString("domain-id"), @types.IDString("talk-id"), "Hello, World!")?

  // Close connection when done
  match await @rpc_client.close(client) {
    | Ok(_) => println("Disconnected")
    | Err(_) => ()
  }

  Ok(())
}
