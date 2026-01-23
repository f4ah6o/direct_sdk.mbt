// Property-based tests for DirectError formatting and constructors.

///|
let msg_gen : @qc.Gen[String] = @qc.Gen::spawn()

///|
let code_gen : @qc.Gen[Int] = @qc.int_range(-1000, 1000)

///|
let error_tag_gen : @qc.Gen[Int] = @qc.int_range(0, 10)

///|
let error_spec_gen : @qc.Gen[(Int, String, Int)] = error_tag_gen.bind(fn(
  tag : Int,
) {
  msg_gen.bind(fn(msg : String) {
    code_gen.fmap(fn(code : Int) { (tag, msg, code) })
  })
})

///|
test "quickcheck: direct_error_to_string matches variant format" {
  let tag_offset = @env.now().to_int() % 11
  @qc.quick_check(
    @qc.forall(error_spec_gen, fn(spec : (Int, String, Int)) {
      let (tag, msg, code) = spec
      let tag = (tag + tag_offset) % 11
      let prop = match tag {
        0 =>
          @errors.direct_error_to_string(@errors.not_connected(msg)) ==
          "not connected: " + msg
        1 =>
          @errors.direct_error_to_string(@errors.timeout(msg)) ==
          "timeout: " + msg
        2 =>
          @errors.direct_error_to_string(@errors.invalid_response(msg)) ==
          "invalid response: " + msg
        3 =>
          @errors.direct_error_to_string(@errors.already_connected(msg)) ==
          "already connected: " + msg
        4 =>
          @errors.direct_error_to_string(@errors.room_not_found(msg)) ==
          "room not found: " + msg
        5 =>
          @errors.direct_error_to_string(@errors.user_not_found(msg)) ==
          "user not found: " + msg
        6 =>
          @errors.direct_error_to_string(@errors.rpc_error(code, msg)) ==
          "RPC error " + code.to_string() + ": " + msg
        7 =>
          @errors.direct_error_to_string(@errors.connection_error(msg)) ==
          "connection failed: " + msg
        8 =>
          @errors.direct_error_to_string(@errors.decode_error(msg)) ==
          "decode error: " + msg
        9 =>
          @errors.direct_error_to_string(@errors.auth_error(msg)) ==
          "authentication error: " + msg
        _ =>
          @errors.direct_error_to_string(@errors.internal_error(msg)) ==
          "internal error: " + msg
      }
      let label = match tag {
        0 => "not_connected"
        1 => "timeout"
        2 => "invalid_response"
        3 => "already_connected"
        4 => "room_not_found"
        5 => "user_not_found"
        6 => "rpc_error"
        7 => "connection_error"
        8 => "decode_error"
        9 => "auth_error"
        _ => "internal_error"
      }
      @qc.collect(prop, label)
    }),
    max_success=1000,
  )
}

///|
test "quickcheck: wrap helpers match constructors" {
  @qc.quick_check(
    @qc.forall(msg_gen, fn(msg : String) {
      @errors.direct_error_to_string(@errors.wrap_connection_error(msg)) ==
      @errors.direct_error_to_string(@errors.connection_error(msg)) &&
      @errors.direct_error_to_string(@errors.wrap_decode_error(msg)) ==
      @errors.direct_error_to_string(@errors.decode_error(msg))
    }),
  )
}
