
///|
/// Rejection sampling: regenerate until the predicate holds.
fn[T] such_that(
  gen : @gen.Generator[T],
  pred : (T) -> Bool
) -> @gen.Generator[T] {
  @gen.Generator::Generator(fn(size, rng) {
    for ;; {
      let v = gen.run(size, rng)
      if pred(v) {
        break v
      }
    }
  })
}

// Property-based tests for core type conversions.

///|
fn is_valid_msg_wire(wire : Int32) -> Bool {
  match wire {
    0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 => true
    500 | 501 | 502 | 503 | 504 | 505 | 506 | 507 | 508 => true
    _ => false
  }
}

///|
let msg_type_gen : @gen.Generator[@types.MessageType] = @gen.elements([
  @types.MsgTypeSystem,
  @types.MsgTypeText,
  @types.MsgTypeStamp,
  @types.MsgTypeLocation,
  @types.MsgTypeFile,
  @types.MsgTypeTextMultipleFile,
  @types.MsgTypeUnused,
  @types.MsgTypeDeleted,
  @types.MsgTypeNoteShared,
  @types.MsgTypeNoteDeleted,
  @types.MsgTypeNoteCreated,
  @types.MsgTypeNoteUpdated,
  @types.MsgTypeOriginalStamp,
  @types.MsgTypeYesNo,
  @types.MsgTypeYesNoReply,
  @types.MsgTypeSelect,
  @types.MsgTypeSelectReply,
  @types.MsgTypeTask,
  @types.MsgTypeTaskDone,
  @types.MsgTypeYesNoClosed,
  @types.MsgTypeSelectClosed,
  @types.MsgTypeTaskClosed,
])

///|
let room_type_gen : @gen.Generator[@types.RoomType] = @gen.elements([
  @types.RoomTypePair,
  @types.RoomTypeGroup,
])

///|
let small_int_gen : @gen.Generator[Int32] = @gen.int_range(-1_000_000, 1_000_000)

///|
let non_numeric_string_gen : @gen.Generator[String] = such_that(@gen.spawn(), fn(
  s : String,
) {
  try @string.parse_int64(s) catch {
    _ => true
  } noraise {
    _ => false
  }
})

///|
let invalid_wire_gen : @gen.Generator[Int32] = such_that(@gen.int_range(-1000, 2000), fn(
  wire : Int32,
) {
  !is_valid_msg_wire(wire)
})

///|
test "quickcheck: MessageType wire roundtrip" {
  @qc.quick_check(
    @qc.forall(msg_type_gen, fn(t : @types.MessageType) {
      @types.wire_to_msg_type(@types.msg_type_to_wire(t)) == Some(t)
    }),
  )
}

///|
test "quickcheck: unknown wire values are rejected" {
  @qc.quick_check(
    @qc.forall(invalid_wire_gen, fn(wire : Int32) {
      @types.wire_to_msg_type(wire) == None
    }),
  )
}

///|
test "quickcheck: RoomType int roundtrip" {
  @qc.quick_check(
    @qc.forall(room_type_gen, fn(room : @types.RoomType) {
      @types.int_to_room_type(@types.room_type_to_int(room)) == Some(room)
    }),
  )
}

///|
test "quickcheck: non-numeric strings map to IDString" {
  @qc.quick_check(
    @qc.forall(non_numeric_string_gen, fn(s : String) {
      @types.string_to_id(s) == @types.IDString(s)
    }),
  )
}

///|
test "quickcheck: IDInt string roundtrip" {
  @qc.quick_check(
    @qc.forall(small_int_gen, fn(i : Int32) {
      let id = @types.IDInt(i.to_int64())
      @types.string_to_id(@types.id_to_string(id)) == id
    }),
  )
}

///|
test "quickcheck: IDInt json roundtrip" {
  @qc.quick_check(
    @qc.forall(small_int_gen, fn(i : Int32) {
      let id = @types.IDInt(i.to_int64())
      @types.json_to_id(@types.id_to_json(id)) == Some(id)
    }),
  )
}

///|
test "quickcheck: IDString json roundtrip" {
  @qc.quick_check(
    @qc.forall(non_numeric_string_gen, fn(s : String) {
      let id = @types.IDString(s)
      @types.json_to_id(@types.id_to_json(id)) == Some(id)
    }),
  )
}
