import QtQuick
import QtQuick.Window
import "../theme"

// Geometric lettering stays sharp at every VM scale and follows the palette.
Image {
    id:root
    width:282;height:44
    sourceSize.width:Math.ceil(width*Math.max(2,Window.window?Window.window.devicePixelRatio:1))
    sourceSize.height:Math.ceil(height*Math.max(2,Window.window?Window.window.devicePixelRatio:1))
    source:"data:image/svg+xml,"+encodeURIComponent(
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 282 44'><defs><linearGradient id='ink' x2='0' y2='1'><stop stop-color='"+Theme.primary+"'/><stop offset='.7' stop-color='"+Theme.primary+"' stop-opacity='.9'/><stop offset='1' stop-color='"+Theme.secondary+"'/></linearGradient></defs><g fill='url(#ink)'>"+
        "<path d='M8 0H44L36 8H10V16H36L44 24V32L36 40H0L8 32H34V24H8L0 16V8Z'/>"+
        "<path transform='translate(54)' d='M0 0H10V30L14 34H32L36 30V0H46V32L38 40H8L0 32Z'/>"+
        "<path transform='translate(110)' d='M8 0H44L36 8H10V16H36L44 24V32L36 40H0L8 32H34V24H8L0 16V8Z'/>"+
        "<path transform='translate(164)' d='M0 40V0H10L36 26V0H46V40H36L10 14V40Z'/>"+
        "<path transform='translate(220)' d='M0 0H10V40H0Z'/>"+
        "<path transform='translate(236)' d='M0 0H12L23 13L34 0H46L29 20L46 40H34L23 27L12 40H0L17 20Z'/></g>"+
        "<path d='M0 43H100M116 43H180M196 43H282' stroke='"+Theme.primary+"' opacity='.3'/></svg>")
}
