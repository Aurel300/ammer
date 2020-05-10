package ammer;

import haxe.macro.Expr;

typedef FFIStructVariable = {
  name:String,
  native:String,
  type:FFIType,
  complexType:ComplexType,
  field:Field,
  getField:Field,
  setField:Field
};
