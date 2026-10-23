import QtQuick

Item {
    id: root

    property string name: "dashboard"
    property color color: themeManager.textSecondary
    property int size: 16

    width: size
    height: size

    onColorChanged: canvas.requestPaint()
    onNameChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.save();
            ctx.scale(width / 24.0, height / 24.0);
            ctx.strokeStyle = root.color;
            ctx.fillStyle = root.color;
            ctx.lineWidth = 1.8;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            var n = root.name.toLowerCase();

            if (n === "dashboard") {
                // 4 squares
                ctx.strokeRect(3, 3, 7, 7);
                ctx.strokeRect(14, 3, 7, 7);
                ctx.strokeRect(3, 14, 7, 7);
                ctx.strokeRect(14, 14, 7, 7);
            } else if (n === "project" || n === "folder") {
                // Folder glyph
                ctx.beginPath();
                ctx.moveTo(3, 7);
                ctx.lineTo(8, 7);
                ctx.lineTo(10, 9);
                ctx.lineTo(21, 9);
                ctx.lineTo(21, 19);
                ctx.lineTo(3, 19);
                ctx.closePath();
                ctx.stroke();
            } else if (n === "repo" || n === "package") {
                // Repository package cube
                ctx.beginPath();
                ctx.moveTo(12, 3);
                ctx.lineTo(21, 7.5);
                ctx.lineTo(21, 16.5);
                ctx.lineTo(12, 21);
                ctx.lineTo(3, 16.5);
                ctx.lineTo(3, 7.5);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(3, 7.5); ctx.lineTo(12, 12); ctx.lineTo(21, 7.5);
                ctx.moveTo(12, 12); ctx.lineTo(12, 21);
                ctx.stroke();
            } else if (n === "branch") {
                // Git branch fork
                ctx.beginPath();
                ctx.arc(6, 6, 2.5, 0, 2 * Math.PI);
                ctx.arc(18, 9, 2.5, 0, 2 * Math.PI);
                ctx.arc(6, 18, 2.5, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(6, 8.5); ctx.lineTo(6, 15.5);
                ctx.moveTo(6, 15.5); ctx.bezierCurveTo(6, 11, 18, 14, 18, 11.5);
                ctx.stroke();
            } else if (n === "commit") {
                // Commit node
                ctx.beginPath();
                ctx.arc(12, 12, 3.5, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(3, 12); ctx.lineTo(8.5, 12);
                ctx.moveTo(15.5, 12); ctx.lineTo(21, 12);
                ctx.stroke();
            } else if (n === "diff" || n === "changes") {
                // Diff file
                ctx.beginPath();
                ctx.moveTo(5, 3); ctx.lineTo(15, 3); ctx.lineTo(19, 7); ctx.lineTo(19, 21); ctx.lineTo(5, 21); ctx.closePath();
                ctx.stroke();
                // Plus and minus lines
                ctx.beginPath();
                ctx.moveTo(9, 11); ctx.lineTo(15, 11); // minus
                ctx.moveTo(12, 14); ctx.lineTo(12, 18); // plus vertical
                ctx.moveTo(10, 16); ctx.lineTo(14, 16); // plus horizontal
                ctx.stroke();
            } else if (n === "history" || n === "activity") {
                // Clock / history circle
                ctx.beginPath();
                ctx.arc(12, 12, 8.5, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(12, 7); ctx.lineTo(12, 12); ctx.lineTo(16, 14);
                ctx.stroke();
            } else if (n === "github") {
                // Sleek Octocat / GitHub cat silhouette
                ctx.beginPath();
                ctx.arc(12, 12, 8.5, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(8, 7); ctx.lineTo(9.5, 10);
                ctx.moveTo(16, 7); ctx.lineTo(14.5, 10);
                ctx.stroke();
            } else if (n === "guide" || n === "book") {
                // Book
                ctx.beginPath();
                ctx.moveTo(4, 5); ctx.lineTo(12, 6); ctx.lineTo(20, 5); ctx.lineTo(20, 19); ctx.lineTo(12, 20); ctx.lineTo(4, 19); ctx.closePath();
                ctx.moveTo(12, 6); ctx.lineTo(12, 20);
                ctx.stroke();
            } else if (n === "settings" || n === "gear") {
                // Settings gear
                ctx.beginPath();
                ctx.arc(12, 12, 4, 0, 2 * Math.PI);
                ctx.stroke();
                for (var i = 0; i < 8; i++) {
                    var ang = i * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(12 + Math.cos(ang) * 6, 12 + Math.sin(ang) * 6);
                    ctx.lineTo(12 + Math.cos(ang) * 9, 12 + Math.sin(ang) * 9);
                    ctx.stroke();
                }
            } else if (n === "plus") {
                ctx.beginPath();
                ctx.moveTo(12, 5); ctx.lineTo(12, 19);
                ctx.moveTo(5, 12); ctx.lineTo(19, 12);
                ctx.stroke();
            } else if (n === "refresh" || n === "sync") {
                ctx.beginPath();
                ctx.arc(12, 12, 7, Math.PI * 0.25, Math.PI * 1.75);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(17, 7); ctx.lineTo(17, 12); ctx.lineTo(12, 12);
                ctx.stroke();
            } else if (n === "search") {
                ctx.beginPath();
                ctx.arc(10.5, 10.5, 6, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(15, 15); ctx.lineTo(20, 20);
                ctx.stroke();
            } else if (n === "pull" || n === "download") {
                ctx.beginPath();
                ctx.moveTo(12, 4); ctx.lineTo(12, 16);
                ctx.lineTo(8, 12); ctx.moveTo(12, 16); ctx.lineTo(16, 12);
                ctx.moveTo(5, 19); ctx.lineTo(19, 19);
                ctx.stroke();
            } else if (n === "push" || n === "upload") {
                ctx.beginPath();
                ctx.moveTo(12, 16); ctx.lineTo(12, 4);
                ctx.lineTo(8, 8); ctx.moveTo(12, 4); ctx.lineTo(16, 8);
                ctx.moveTo(5, 19); ctx.lineTo(19, 19);
                ctx.stroke();
            } else if (n === "shield" || n === "lock") {
                ctx.beginPath();
                ctx.moveTo(12, 3);
                ctx.lineTo(20, 6.5);
                ctx.lineTo(20, 12);
                ctx.bezierCurveTo(20, 17, 12, 21, 12, 21);
                ctx.bezierCurveTo(12, 21, 4, 17, 4, 12);
                ctx.lineTo(4, 6.5);
                ctx.closePath();
                ctx.stroke();
            } else if (n === "external") {
                ctx.beginPath();
                ctx.moveTo(18, 13); ctx.lineTo(18, 19); ctx.lineTo(5, 19); ctx.lineTo(5, 6); ctx.lineTo(11, 6);
                ctx.moveTo(14, 4); ctx.lineTo(20, 4); ctx.lineTo(20, 10);
                ctx.moveTo(20, 4); ctx.lineTo(11, 13);
                ctx.stroke();
            } else if (n === "trash") {
                ctx.beginPath();
                ctx.moveTo(4, 6); ctx.lineTo(20, 6);
                ctx.moveTo(9, 6); ctx.lineTo(9, 3); ctx.lineTo(15, 3); ctx.lineTo(15, 6);
                ctx.moveTo(6, 6); ctx.lineTo(7, 20); ctx.lineTo(17, 20); ctx.lineTo(18, 6);
                ctx.stroke();
            } else if (n === "check") {
                ctx.beginPath();
                ctx.moveTo(4, 12); ctx.lineTo(9, 17); ctx.lineTo(20, 6);
                ctx.stroke();
            } else if (n === "sun") {
                ctx.beginPath();
                ctx.arc(12, 12, 4.5, 0, 2 * Math.PI);
                ctx.stroke();
                for (var j = 0; j < 8; j++) {
                    var a = j * Math.PI / 4;
                    ctx.beginPath();
                    ctx.moveTo(12 + Math.cos(a) * 6.5, 12 + Math.sin(a) * 6.5);
                    ctx.lineTo(12 + Math.cos(a) * 8.5, 12 + Math.sin(a) * 8.5);
                    ctx.stroke();
                }
            } else if (n === "code" || n === "terminal") {
                // Code brackets < / >
                ctx.beginPath();
                ctx.moveTo(8, 7); ctx.lineTo(3, 12); ctx.lineTo(8, 17);
                ctx.moveTo(16, 7); ctx.lineTo(21, 12); ctx.lineTo(16, 17);
                ctx.moveTo(14, 5); ctx.lineTo(10, 19);
                ctx.stroke();
            } else if (n === "file" || n === "document") {
                // File sheet
                ctx.beginPath();
                ctx.moveTo(5, 3); ctx.lineTo(14, 3); ctx.lineTo(19, 8); ctx.lineTo(19, 21); ctx.lineTo(5, 21); ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(14, 3); ctx.lineTo(14, 8); ctx.lineTo(19, 8);
                ctx.stroke();
            } else if (n === "save" || n === "disk") {
                // Save floppy icon
                ctx.beginPath();
                ctx.moveTo(4, 4); ctx.lineTo(16, 4); ctx.lineTo(20, 8); ctx.lineTo(20, 20); ctx.lineTo(4, 20); ctx.closePath();
                ctx.stroke();
                ctx.strokeRect(8, 4, 8, 5);
                ctx.strokeRect(7, 13, 10, 7);
            } else if (n === "moon") {
                ctx.beginPath();
                ctx.arc(12, 12, 7, Math.PI * 0.2, Math.PI * 1.5);
                ctx.bezierCurveTo(10, 11, 10, 7, 14, 5.5);
                ctx.stroke();
            } else {
                // Default clean dot
                ctx.beginPath();
                ctx.arc(12, 12, 3, 0, 2 * Math.PI);
                ctx.fill();
            }

            ctx.restore();
        }
    }
}
