import QtQuick
import QtQuick.Effects

// Shadow's body on Qt 6.9 and newer (see Shadow.qml): the settings come from the Shadow around it.
RectangularShadow {
	readonly property Item shadow: parent?.parent ?? null

	radius: shadow?.radius ?? 0
	blur: shadow?.blur ?? 24
	offset.y: shadow?.offsetY ?? 4
	color: shadow?.color ?? "transparent"
}
