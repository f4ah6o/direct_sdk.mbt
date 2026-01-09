// Tests for core types
// Reference: direct-go-sdk/direct-go/types_test.go

///|
test "msg_type_to_wire converts message types correctly" {
  inspect(@types.msg_type_to_wire(@types.MsgTypeText), content="1")
  inspect(@types.msg_type_to_wire(@types.MsgTypeStamp), content="2")
  inspect(@types.msg_type_to_wire(@types.MsgTypeYesNo), content="500")
  inspect(@types.msg_type_to_wire(@types.MsgTypeSelect), content="502")
}

///|
test "wire_to_msg_type converts wire values to message types" {
  inspect(@types.wire_to_msg_type(1), content="Some(MsgTypeText)")
  inspect(@types.wire_to_msg_type(2), content="Some(MsgTypeStamp)")
  inspect(@types.wire_to_msg_type(500), content="Some(MsgTypeYesNo)")
  inspect(@types.wire_to_msg_type(502), content="Some(MsgTypeSelect)")
  inspect(@types.wire_to_msg_type(999), content="None")
}

///|
test "id_to_string converts ID to string" {
  let string_id = @types.IDString("test-id")
  inspect(@types.id_to_string(string_id), content="test-id")
  let int_id = @types.IDInt(123L)
  inspect(@types.id_to_string(int_id), content="123")
}

///|
test "string_to_id parses string to ID" {
  let id1 = @types.string_to_id("test-id")
  inspect(id1, content="IDString(\"test-id\")")
  let id2 = @types.string_to_id("123")
  inspect(id2, content="IDInt(123)")
}

///|
test "id_to_json converts ID to JsonValue" {
  let string_id = @types.IDString("test-id")
  let json1 = @types.id_to_json(string_id)
  inspect(json1, content="JsonString(\"test-id\")")
  let int_id = @types.IDInt(123L)
  let json2 = @types.id_to_json(int_id)
  inspect(json2, content="JsonNumber(123)")
}

///|
test "json_to_id parses JsonValue to ID" {
  let json1 = @types.JsonString("test-id")
  inspect(@types.json_to_id(json1), content="Some(IDString(\"test-id\"))")
  let json2 = @types.JsonNumber(123.0)
  inspect(@types.json_to_id(json2), content="Some(IDInt(123))")
  let json3 = @types.JsonBool(true)
  inspect(@types.json_to_id(json3), content="None")
}

///|
test "room_type_to_int converts room types" {
  inspect(@types.room_type_to_int(@types.RoomTypePair), content="1")
  inspect(@types.room_type_to_int(@types.RoomTypeGroup), content="2")
}

///|
test "int_to_room_type parses int to room type" {
  inspect(@types.int_to_room_type(1), content="Some(RoomTypePair)")
  inspect(@types.int_to_room_type(2), content="Some(RoomTypeGroup)")
  inspect(@types.int_to_room_type(3), content="None")
}
