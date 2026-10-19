// Panchang.js (the shell's Hindu month and season) against festivals whose dates are known.
//   node tests/panchang.js <Panchang.js>     exit 1 on a wrong month
const fs = require("fs"), vm = require("vm");
const ctx = {};
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(process.argv[2], "utf8").replace(/^\.pragma library/m, "") +
	"\nObject.assign(this, { month, season, hindiDate, greeting });", ctx);
const at = d => new Date(`${d}T12:00:00+05:30`);
const cases = [ // date, month index (0 चैत … 11 फागुन), why
	["2025-03-14", 11, "Holi 2025: फागुन's full moon, still फागुन"],
	["2025-03-20", 0, "the dark fortnight after Holi is चैत"],
	["2025-08-05", 4, "सावन, before Raksha Bandhan (9 Aug)"],
	["2025-10-27", 7, "Chhath 2025, कातिक"],
	["2025-11-05", 7, "Dev Diwali, कातिक's full moon"],
	["2026-03-01", 11, "फागुन, before Holi 2026 (3 Mar)"],
	["2026-03-10", 0, "चैत, after Holi 2026"],
	["2026-10-20", 6, "कुआर, before Sharad Purnima (26 Oct)"],
	["2026-11-15", 7, "Chhath 2026, कातिक"],
];
let bad = 0;
for (const [d, want, why] of cases) {
	const got = ctx.month(at(d));
	if (got !== want) { console.log(`${d}: ${got}, not ${want} (${why})`); bad++; }
}
const checks = [
	[ctx.season(at("2026-10-20")), "कुआर · शरद ऋतु"],
	[ctx.season(at("2025-03-20")), "चैत · वसंत ऋतु · चैता"],
	[ctx.hindiDate(at("2026-10-19")), "सोमवार, १९ अक्टूबर"],
	[ctx.greeting(new Date(2026, 9, 19, 8)), "राम राम"],
	[ctx.greeting(new Date(2026, 9, 19, 19)), "का हाल बा?"],
];
for (const [got, want] of checks) if (got !== want) { console.log(`${got} != ${want}`); bad++; }
process.exit(bad ? 1 : 0);
