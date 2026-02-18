///|
test "notify_create_attachment enriches notify_create_message" {
  let dispatcher = new_dispatcher()
  let messages : Array[@types.ReceivedMessage] = []
  on_message(dispatcher, fn(msg) { messages.push(msg) })

  let attachment = @types.JsonObject(
    Map::from_array([
      ("talkId", @types.JsonInt(100L)),
      ("messageId", @types.JsonInt(200L)),
      ("url", @types.JsonString("https://example.test/files/abc")),
      ("name", @types.JsonString("sample.txt")),
      ("contentType", @types.JsonString("text/plain")),
    ]),
  )
  emit(dispatcher, "notify_create_attachment", attachment)

  let content = @types.JsonObject(
    Map::from_array([("text", @types.JsonString("attached"))]),
  )
  let message = @types.JsonObject(
    Map::from_array([
      ("id", @types.JsonInt(200L)),
      ("talk_id", @types.JsonInt(100L)),
      ("user_id", @types.JsonInt(300L)),
      ("domain_id", @types.JsonInt(400L)),
      ("type", @types.JsonInt(4L)),
      ("content", content),
    ]),
  )
  emit(dispatcher, "notify_create_message", message)

  inspect(messages.length(), content="1")
  inspect(messages[0].attachment_url, content="https://example.test/files/abc")
  inspect(messages[0].attachment_name, content="sample.txt")
  inspect(messages[0].attachment_content_type, content="text/plain")
  match messages[0].content {
    @types.JsonObject(obj) =>
      inspect(
        obj.get("attachment_url"),
        content="Some(JsonString(\"https://example.test/files/abc\"))",
      )
    _ => inspect("unexpected", content="unexpected")
  }
}

///|
test "notify_create_message can read attachment url from content" {
  let dispatcher = new_dispatcher()
  let messages : Array[@types.ReceivedMessage] = []
  on_message(dispatcher, fn(msg) { messages.push(msg) })

  let attachment = @types.JsonObject(
    Map::from_array([
      ("url", @types.JsonString("https://example.test/files/from-content")),
      ("name", @types.JsonString("from-content.txt")),
    ]),
  )
  let content = @types.JsonObject(
    Map::from_array([
      ("text", @types.JsonString("attached")),
      ("attachment", attachment),
    ]),
  )
  let message = @types.JsonObject(
    Map::from_array([
      ("id", @types.JsonInt(201L)),
      ("talk_id", @types.JsonInt(101L)),
      ("type", @types.JsonInt(4L)),
      ("content", content),
    ]),
  )
  emit(dispatcher, "notify_create_message", message)

  inspect(messages.length(), content="1")
  inspect(
    messages[0].attachment_url,
    content="https://example.test/files/from-content",
  )
  inspect(messages[0].attachment_name, content="from-content.txt")
}
