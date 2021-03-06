// RUN: %target-swift-frontend -parse -verify -import-cf-types -I %S/Inputs/custom-modules %s

// REQUIRES: objc_interop

import CoreCooling
import CFAndObjC

func assertUnmanaged<T: AnyObject>(_ t: Unmanaged<T>) {}
func assertManaged<T: AnyObject>(_ t: T) {}

func test0(_ fridge: CCRefrigerator) {
  assertManaged(fridge)
}

func test1(_ power: Unmanaged<CCPowerSupply>) {
  assertUnmanaged(power)
  let fridge = CCRefrigeratorCreate(power) // expected-error {{cannot convert value of type 'Unmanaged<CCPowerSupply>' to expected argument type 'CCPowerSupply!'}}
  assertUnmanaged(fridge)
}

func test2() {
  let fridge = CCRefrigeratorCreate(kCCPowerStandard)
  assertUnmanaged(fridge)
}

func test3(_ fridge: CCRefrigerator) {
  assertManaged(fridge)
}

func test4() {
  // FIXME: this should not require a type annotation
  let power: CCPowerSupply = kCCPowerStandard
  assertManaged(power)
  let fridge = CCRefrigeratorCreate(power)
  assertUnmanaged(fridge)
}

func test5() {
  let power: Unmanaged<CCPowerSupply> = .passUnretained(kCCPowerStandard)
  assertUnmanaged(power)
  _ = CCRefrigeratorCreate(power.takeUnretainedValue())
}

func test6() {
  let fridge = CCRefrigeratorCreate(nil)
  fridge?.release()
}

func test7() {
  let value = CFBottom()
  assertUnmanaged(value)
}

func test8(_ f: CCRefrigerator) {
  _ = f as CFTypeRef
  _ = f as AnyObject
}

func test9() {
  let fridge = CCRefrigeratorCreateMutable(kCCPowerStandard).takeRetainedValue()
  let constFridge: CCRefrigerator = fridge
  CCRefrigeratorOpen(fridge)
  let item = CCRefrigeratorGet(fridge, 0).takeUnretainedValue()
  CCRefrigeratorInsert(item, fridge) // expected-error {{cannot convert value of type 'CCItem' to expected argument type 'CCMutableRefrigerator!'}}
  CCRefrigeratorInsert(constFridge, item) // expected-error {{cannot convert value of type 'CCRefrigerator' to expected argument type 'CCMutableRefrigerator!'}}
  CCRefrigeratorInsert(fridge, item)
  CCRefrigeratorClose(fridge)
}

func testProperty(_ k: Kitchen) {
  k.fridge = CCRefrigeratorCreate(kCCPowerStandard).takeRetainedValue()
  CCRefrigeratorOpen(k.fridge)
  CCRefrigeratorClose(k.fridge)
}

func testTollFree0(_ mduct: MutableDuct) {
  _ = mduct as CCMutableDuct

  let duct = mduct as Duct
  _ = duct as CCDuct
}

func testTollFree1(_ ccmduct: CCMutableDuct) {
  _ = ccmduct as MutableDuct

  let ccduct: CCDuct = ccmduct
  _ = ccduct as Duct
}

func testChainedAliases(_ fridge: CCRefrigerator) {
  _ = fridge as CCRefrigerator

  _ = fridge as CCFridge
  _ = fridge as CCFridgeRef // expected-error{{'CCFridgeRef' is unavailable in Swift}}
}

func testBannedImported(_ object: CCOpaqueTypeRef) {
  CCRetain(object) // expected-error {{'CCRetain' is unavailable: Core Foundation objects are automatically memory managed}}
  CCRelease(object) // expected-error {{'CCRelease' is unavailable: Core Foundation objects are automatically memory managed}}
}

func testOutParametersGood() {
  var fridge: CCRefrigerator?
  CCRefrigeratorCreateIndirect(&fridge)

  var power: CCPowerSupply?
  CCRefrigeratorGetPowerSupplyIndirect(fridge!, &power)

  var item: Unmanaged<CCItem>?
  CCRefrigeratorGetItemUnaudited(fridge!, 0, &item)
}

func testOutParametersBad() {
  let fridge: CCRefrigerator?
  CCRefrigeratorCreateIndirect(fridge) // expected-error {{cannot convert value of type 'CCRefrigerator?' to expected argument type 'UnsafeMutablePointer<CCRefrigerator?>?'}}

  let power: CCPowerSupply?
  CCRefrigeratorGetPowerSupplyIndirect(0, power) // expected-error {{cannot convert value of type 'Int' to expected argument type 'CCRefrigerator!'}}

  let item: CCItem?
  CCRefrigeratorGetItemUnaudited(0, 0, item) // expected-error {{cannot convert value of type 'Int' to expected argument type 'CCRefrigerator!'}}
}

func nameCollisions() {
  var objc: MyProblematicObject?
  var cf: MyProblematicObjectRef?
  cf = objc // expected-error {{cannot assign value of type 'MyProblematicObject?' to type 'MyProblematicObjectRef?'}}
  objc = cf // expected-error {{cannot assign value of type 'MyProblematicObjectRef?' to type 'MyProblematicObject?'}}

  var cfAlias: MyProblematicAliasRef?
  cfAlias = cf // okay
  cf = cfAlias // okay

  var otherAlias: MyProblematicAlias?
  otherAlias = cfAlias // expected-error {{cannot assign value of type 'MyProblematicAliasRef?' to type 'MyProblematicAlias?'}}
  cfAlias = otherAlias // expected-error {{cannot assign value of type 'MyProblematicAlias?' to type 'MyProblematicAliasRef?'}}

  func isOptionalFloat(_: inout Optional<Float>) {}
  isOptionalFloat(&otherAlias) // okay

  var np: NotAProblem?
  var np2: NotAProblemRef? // expected-error{{'NotAProblemRef' is unavailable in Swift}}

  np = np2
  np2 = np
}
