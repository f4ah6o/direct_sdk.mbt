// Error handling for Direct SDK
// Reference: direct-go-sdk/direct-go/errors.go

// DirectError represents all possible errors in the SDK
pub type DirectError =
  | NotConnected(String)        // Client is not connected
  | Timeout(String)             // Request timed out
  | InvalidResponse(String)     // Invalid server response
  | AlreadyConnected(String)    // Client is already connected
  | RoomNotFound(String)        // Room/Talk not found
  | UserNotFound(String)        // User not found
  | RPCError(Int, String)       // RPC error from server (code, message)
  | ConnectionError(String)     // WebSocket connection failed
  | DecodeError(String)         // MessagePack/JSON decode error
  | AuthError(String)           // Authentication error
  | InternalError(String)       // Internal SDK error

// Convert DirectError to String for display
pub fn direct_error_to_string(e : DirectError) -> String {
  match e {
    | NotConnected(msg) => "not connected: " + msg
    | Timeout(msg) => "timeout: " + msg
    | InvalidResponse(msg) => "invalid response: " + msg
    | AlreadyConnected(msg) => "already connected: " + msg
    | RoomNotFound(msg) => "room not found: " + msg
    | UserNotFound(msg) => "user not found: " + msg
    | RPCError(code, msg) => "RPC error " + code.to_string() + ": " + msg
    | ConnectionError(msg) => "connection failed: " + msg
    | DecodeError(msg) => "decode error: " + msg
    | AuthError(msg) => "authentication error: " + msg
    | InternalError(msg) => "internal error: " + msg
  }
}

// Create specific error constructors

pub fn not_connected(msg : String) -> DirectError {
  NotConnected(msg)
}

pub fn timeout(msg : String) -> DirectError {
  Timeout(msg)
}

pub fn invalid_response(msg : String) -> DirectError {
  InvalidResponse(msg)
}

pub fn already_connected(msg : String) -> DirectError {
  AlreadyConnected(msg)
}

pub fn room_not_found(msg : String) -> DirectError {
  RoomNotFound(msg)
}

pub fn user_not_found(msg : String) -> DirectError {
  UserNotFound(msg)
}

pub fn rpc_error(code : Int, msg : String) -> DirectError {
  RPCError(code, msg)
}

pub fn connection_error(msg : String) -> DirectError {
  ConnectionError(msg)
}

pub fn decode_error(msg : String) -> DirectError {
  DecodeError(msg)
}

pub fn auth_error(msg : String) -> DirectError {
  AuthError(msg)
}

pub fn internal_error(msg : String) -> DirectError {
  InternalError(msg)
}

// Helper to wrap underlying errors
pub fn wrap_connection_error(cause : String) -> DirectError {
  ConnectionError(cause)
}

pub fn wrap_decode_error(cause : String) -> DirectError {
  DecodeError(cause)
}

// Result type alias for convenience
// Use: type Result[T] = Result[T, DirectError]
// This is already built into Moonbit's standard library
