package test;

import Templates.XTemplatesStruct;

class TestCpp extends Test {
  function testTemplates() {
    eq(Templates.templated_add_ints32(0, 0), 0);
    eq(Templates.templated_add_ints32(1, 2), 3);
    eq(Templates.templated_add_ints32(-1, 1), 0);
    eq(Templates.templated_add_ints32(0xFFFFFFFF, 1), 0);
    eq(Templates.templated_add_ints32(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    eq(Templates.templated_add_ints32(-0x7FFFFFFF, 0x7FFFFFFF), 0);
  }

  function testCppLinkage() {
    Templates.cpp_nop();
    eq(1, 1);
  }

  function testStructMembers() {
    var obj = XTemplatesStruct.new_();
    eq(obj.member_int, 5);
    obj.member_int = 7;
    eq(obj.member_int, 7);
    eq(obj.add(13), 20);
  }
}
