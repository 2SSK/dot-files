.pragma library
// The Hindu month as Bihar counts it (purnimanta: full moon to full moon), its ritu, and the folk
// songs of its season, from the moon's mean phase and the sun's sidereal sign (Lahiri). Good to
// a day either side of a full or new moon; adhik (leap) months aren't marked.

const MONTHS = ["चैत", "बैसाख", "जेठ", "असाढ़", "सावन", "भादो", "कुआर", "कातिक", "अगहन", "पूस", "माघ", "फागुन"];
const RITUS = ["वसंत", "ग्रीष्म", "वर्षा", "शरद", "हेमंत", "शिशिर"]; // two months each, from चैत
const SONGS = { 0: "चैता", 4: "कजरी", 5: "कजरी", 7: "छठ के गीत", 11: "फगुआ" };

const SYNODIC = 29.530588853;
const NEW_MOON = 2451550.09766; // 2000-01-06 18:14 UTC

function julian(date) {
    return date.getTime() / 86400000 + 2440587.5;
}

// the sun's sidereal sign at a julian day: 0 Mesha … 11 Meena
function rashi(jd) {
    const n = jd - 2451545;
    const g = (357.528 + 0.9856003 * n) * Math.PI / 180;
    const tropical = 280.460 + 0.9856474 * n + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g);
    const ayanamsa = 23.853 + 0.013964 * n / 365.25;
    return Math.floor((((tropical - ayanamsa) % 360) + 360) % 360 / 30);
}

// the amanta month starting at a new moon: the sun in Meena then makes it चैत
function amanta(newMoon) {
    return (rashi(newMoon) + 1) % 12;
}

// the month index (0 चैत … 11 फागुन): after the full moon, the dark fortnight already belongs to the
// next month, as Bihar counts them
function month(date) {
    const jd = julian(date);
    const last = NEW_MOON + Math.floor((jd - NEW_MOON) / SYNODIC) * SYNODIC;
    return jd >= last + SYNODIC / 2 ? amanta(last + SYNODIC) : amanta(last);
}

// "कुआर · शरद ऋतु", with the season's songs when it has them: "चैत · वसंत ऋतु · चैता"
function season(date) {
    const m = month(date);
    return [MONTHS[m], RITUS[Math.floor(m / 2)] + " ऋतु", SONGS[m]].filter(Boolean).join(" · ");
}
