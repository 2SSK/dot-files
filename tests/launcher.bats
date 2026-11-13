#!/usr/bin/env bats
# The launcher's calculator (services/calc.js): a sum typed in Apps mode, worked out by a parser of
# its own (never eval). The file is QML's JavaScript, read here without its ".pragma library" line.

calc() {
	node -e '
const fs = require("fs");
const src = fs.readFileSync(process.argv[1], "utf8").replace(/^\.pragma library.*$/m, "");
const calculate = new Function(src + "; return calculate;")();
const r = calculate(process.argv[2]);
console.log(r === null ? "null" : r.value);' "$BATS_TEST_DIRNAME/../.config/quickshell/desktop/services/calc.js" "$1"
}

@test "sums: the four operations, powers, brackets, and precedence" {
	[ "$(calc '12*4')" = 48 ]
	[ "$(calc '2 + 3 * 4')" = 14 ]
	[ "$(calc '(2 + 3) * 4')" = 20 ]
	[ "$(calc '2^10')" = 1024 ]
	[ "$(calc '2^3^2')" = 512 ] # powers group from the right
	[ "$(calc '7 / 2')" = 3.5 ]
	[ "$(calc '-3 + 5')" = 2 ]
	[ "$(calc '10 % 3')" = 1 ]
}

@test "sums: as people type them: x and ×, ÷, spaces, a comma in a thousand" {
	[ "$(calc '3 x 4')" = 12 ]
	[ "$(calc '3×4')" = 12 ]
	[ "$(calc '9 ÷ 3')" = 3 ]
	[ "$(calc '1,250 * 2')" = 2500 ]
}

@test "sums: percentages, constants and functions" {
	[ "$(calc '15% of 80')" = 12 ]
	[ "$(calc '200 + 10%')" = 220 ]
	[ "$(calc 'sqrt(16) + abs(-2)')" = 6 ]
	[ "$(calc 'round(pi * 100) / 100')" = 3.14 ]
	[ "$(calc 'log(1000)')" = 3 ]
	[ "$(calc 'ln(e)')" = 1 ]
}

@test "results: no floating-point noise, and big ones readable" {
	[ "$(calc '0.1 + 0.2')" = 0.3 ]
	[ "$(calc '1/3')" = 0.3333333333 ]
}

@test "not a sum: names, plain numbers, nonsense and code are left alone" {
	[ "$(calc 'firefox')" = null ]
	[ "$(calc '42')" = null ]
	[ "$(calc '2 +')" = null ]
	[ "$(calc '1/0')" = null ]
	[ "$(calc 'alert(1)')" = null ]
	[ "$(calc 'constructor')" = null ]
	[ "$(calc '14:30')" = null ] # a time: the converter's
}
