import QtQuick
import qs

// A small area graph of `values` (0–`max`), newest on the right.
Canvas {
	id: root

	property var values: []
	property real max: 1
	property color tint: Theme.primary

	onValuesChanged: requestPaint()
	onTintChanged: requestPaint()

	onPaint: {
		const ctx = getContext("2d");
		ctx.reset();
		if (values.length < 2)
			return;
		const step = width / 59;
		const x0 = width - (values.length - 1) * step;
		const y = v => height - Math.max(0, Math.min(1, v / max)) * (height - 2) - 1;
		ctx.beginPath();
		ctx.moveTo(x0, height);
		values.forEach((v, i) => ctx.lineTo(x0 + i * step, y(v)));
		ctx.lineTo(width, height);
		ctx.closePath();
		ctx.fillStyle = Qt.alpha(tint, 0.18);
		ctx.fill();
		ctx.beginPath();
		values.forEach((v, i) => i ? ctx.lineTo(x0 + i * step, y(v)) : ctx.moveTo(x0, y(v)));
		ctx.strokeStyle = tint;
		ctx.lineWidth = 2;
		ctx.stroke();
	}
}
