class_name ApolloPalette
extends RefCounted
## Every colour the code uses, by name. All of them are Apollo colours (see DESIGN.md, "Art").
##
## Pick colours from here only, never as raw numbers in a script. Screens that give
## colours their own roles (e.g. EmberTreePalette) build those roles from these.
## The full Apollo palette has 46 colours; every one is named here.

const OUTLINE := Color("090a14")
const NIGHT := Color("10141f")
const DARK := Color("151d28")
const NAVY := Color("172038")
const NAVY_MID := Color("253a5e")
const INDIGO := Color("1e1d39")
const SLATE := Color("202e37")
const STONE := Color("394a50")
const STONE_LIGHT := Color("577277")
const GREY := Color("819796")
const GREY_LIGHT := Color("a8b5b2")
const SILVER := Color("c7cfcc")
const WHITE := Color("ebede9")
const CREAM := Color("e7d5b3")

const RED := Color("a53030")
const RED_LIGHT := Color("cf573c")
const WINE := Color("752438")
const PLUM_DARK := Color("411d31")
const COAL := Color("341c27")
const COAL_DARK := Color("241527")
const BRICK := Color("602c2c")
const RUST := Color("884b2b")
const MAROON := Color("4d2b32")

const ORANGE := Color("de9e41")
const ORANGE_MID := Color("da863e")
const ORANGE_DARK := Color("be772b")
const GOLD := Color("e8c170")

const GREEN := Color("75a743")
const GREEN_LIGHT := Color("a8ca58")
const LIME_PALE := Color("d0da91")
const GREEN_DEEP := Color("468232")
const FOREST := Color("25562e")
const FOREST_DARK := Color("19332d")

const BLUE_DEEP := Color("3c5e8b")
const BLUE := Color("4f8fba")
const SKY := Color("73bed3")
const SKY_LIGHT := Color("a4dddb")

const PINK := Color("df84a5")
const MAGENTA := Color("a23e8c")
const ROSE := Color("c65197")
const PURPLE := Color("7a367b")
const PURPLE_DARK := Color("402751")
const CORK := Color("ad7757")
const CORK_DARK := Color("7a4841")
const TAN := Color("c09473")
const SAND := Color("d7b594")
