///|
test "direct SDK version resolution supports current and legacy manifests" {
  let current =
    #|name = "f4ah6o/direct_sdk"
    #|version = "0.11.2"
    #|

  assert_eq(parse_direct_sdk_version(current), Some("0.11.2"))

  let legacy = "{\"name\":\"f4ah6o/direct_sdk\",\"version\":\"0.11.1\"}"
  assert_eq(parse_direct_sdk_version(legacy), Some("0.11.1"))

  let other_package =
    #|name = "local/other"
    #|version = "9.9.9"
    #|

  assert_eq(parse_direct_sdk_version(other_package), None)
}
