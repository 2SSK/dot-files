.pragma library

// The launcher's calculator: a sum as people type it ("12*4", "3 x 4", "2^10", "15% of 80",
// "200 + 10%", "sqrt(2)") worked out by a parser of its own: nothing typed is ever run as code.
// calculate(text) gives { value, name, detail, copy } for a sum, else null: for a name, a plain number,
// a time ("14:30", the converter's) or anything it can't read whole.

const FUNCTIONS = {
	sqrt: Math.sqrt, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil,
	log: Math.log10, ln: Math.log, sin: Math.sin, cos: Math.cos, tan: Math.tan
};
const CONSTANTS = { pi: Math.PI, e: Math.E };

function tokens(text) {
	const out = [];
	const re = /\s*(?:(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?|\.\d+)|([a-z]+)|([-+*/^%()×÷]))/y;
	let at = 0;
	text = text.toLowerCase();
	while (at < text.length) {
		if (/^\s*$/.test(text.slice(at)))
			break;
		re.lastIndex = at;
		const m = re.exec(text);
		if (!m)
			return null; // a character no sum has (":" of a time, quotes, ...)
		at = re.lastIndex;
		if (m[1] !== undefined)
			out.push({ kind: "num", value: parseFloat(m[1].replace(/,/g, "")) });
		else if (m[2] !== undefined)
			out.push(m[2] === "x" ? { kind: "op", value: "*" } : { kind: "name", value: m[2] });
		else
			out.push({ kind: "op", value: m[3] === "×" ? "*" : m[3] === "÷" ? "/" : m[3] });
	}
	return out;
}

function calculate(text) {
	const list = tokens(text.trim());
	if (!list || list.length === 0)
		return null;
	let i = 0, worked = 0; // worked: operations and functions seen (a bare number isn't a sum)
	const peek = () => list[i];
	const isOp = v => peek() && peek().kind === "op" && peek().value === v;
	const isName = v => peek() && peek().kind === "name" && peek().value === v;
	const fail = () => { throw new Error("not a sum"); };

	// a value, and whether it was written as a percentage (for "200 + 10%")
	function primary() {
		const t = list[i++];
		if (!t)
			fail();
		if (t.kind === "num")
			return t.value;
		if (t.kind === "op" && t.value === "(") {
			const v = expr();
			if (!isOp(")"))
				fail();
			i++;
			return v;
		}
		if (t.kind === "name" && Object.prototype.hasOwnProperty.call(CONSTANTS, t.value)) {
			worked++;
			return CONSTANTS[t.value];
		}
		if (t.kind === "name" && Object.prototype.hasOwnProperty.call(FUNCTIONS, t.value) && isOp("(")) {
			worked++;
			return FUNCTIONS[t.value](primary());
		}
		fail();
	}

	// "10%" is a tenth, unless "%" goes on to an operand: then it's the remainder (10 % 3)
	function postfix() {
		let v = primary(), pct = false;
		const next = list[i + 1];
		if (isOp("%") && !(next && (next.kind === "num" || (next.kind === "op" && next.value === "(") || (next.kind === "name" && next.value !== "of")))) {
			i++;
			worked++;
			v /= 100;
			pct = true;
		}
		return { v, pct };
	}

	function power() {
		const base = postfix();
		if (isOp("^")) {
			i++;
			worked++;
			return { v: Math.pow(base.v, unary().v), pct: false }; // right to left: 2^3^2 = 2^9
		}
		return base;
	}

	function unary() {
		if (isOp("-") || isOp("+")) {
			const minus = list[i++].value === "-";
			const r = unary();
			return { v: minus ? -r.v : r.v, pct: r.pct };
		}
		return power();
	}

	function term() {
		let left = unary();
		for (;;) {
			if (isName("of")) { // "15% of 80"
				i++;
				worked++;
				left = { v: left.v * unary().v, pct: false };
			} else if (isOp("*") || isOp("/") || isOp("%")) {
				const op = list[i++].value;
				worked++;
				const right = unary().v;
				left = { v: op === "*" ? left.v * right : op === "/" ? left.v / right : left.v % right, pct: false };
			} else {
				return left;
			}
		}
	}

	function expr() {
		let left = term().v;
		while (isOp("+") || isOp("-")) {
			const op = list[i++].value;
			worked++;
			const right = term();
			const amount = right.pct ? left * right.v : right.v; // 200 + 10% is 200 and a tenth of it
			left = op === "+" ? left + amount : left - amount;
		}
		return left;
	}

	let value;
	try {
		value = expr();
	} catch (e) {
		return null;
	}
	if (i !== list.length || worked === 0 || !isFinite(value))
		return null;
	value = Number(value.toPrecision(10)); // 0.1 + 0.2 is 0.3, not 0.30000000000000004
	const shown = Math.abs(value) >= 1e4 && Number.isInteger(value) ? value.toLocaleString("en-US") : String(value);
	return { value, convert: true, glyph: "calculator", name: `${text.trim()}  =  ${shown}`, detail: `Enter copies ${value}`, copy: String(value) };
}
