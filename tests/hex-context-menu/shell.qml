import QtQuick
import Quickshell
import QtTest
import "../../configs/quickshell/components"
ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 700; implicitHeight: 500
        HexContextMenu { id: menu; onTriggered: action=> {window.lastAction=action;} }
        TestCase {id: pointer;when:false}
        property string lastAction: ""
        Timer {
            running:true;interval:700
            onTriggered: {
                function check(value,label) {if(!value)throw new Error(label);}
                const items=[{label:"Open",icon:"folder",action:"open"},{label:"Disabled",action:"disabled",enabled:false},{label:"More",items:[{label:"Nested",action:"nested"}]},{label:"Four",action:"four"},{label:"Five",action:"five"},{label:"Six",action:"six"}];
                menu.showAt(window.contentItem,350,250,items,"TEST");
                check(menu.visible,"opens");
                check(menu.x+menu.width/2===350 && menu.y+menu.height/2===250,"cursor centered");
                for(let i=0;i<6;i++) {
                    const p=menu.pointAt((i*60-90)*Math.PI/180,menu.radius*.66);
                    check(menu.hit(p.x,p.y)===i,"sector hit "+i);
                }
                check(menu.hit(menu.width/2,menu.height/2)===-1,"center not an action");
                menu.activate(1);check(window.lastAction===""&&menu.visible,"disabled action");
                menu.activate(2);check(menu.pages.length===1&&menu.actions[0].label==="Nested","submenu");
                menu.back();check(menu.pages.length===0&&menu.actions.length===6,"back");
                const target=menu.pointAt(-Math.PI/2,menu.radius*.66);
                pointer.mouseClick(menu.contentItem,target.x,target.y,Qt.LeftButton);
                check(window.lastAction==="open","pointer dispatch");
                menu.showAt(window.contentItem,0,0,items,"EDGE");check(menu.x>=0&&menu.y>=0,"top edge");
                menu.showAt(window.contentItem,700,500,items,"EDGE");check(menu.x+menu.width<=700&&menu.y+menu.height<=500,"bottom edge");
                console.log("HEX TEST PASS");
                menu.close();Qt.quit();
            }
        }
    }
}
