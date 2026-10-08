// Functional smoke test: real PTY, ANSI/Unicode output, clipboard input and resize.
#include "window.hpp"
#include <QTemporaryDir>
int main(int argc,char **argv){
    QApplication app(argc,argv);if(argc!=2)return 2;
    Palette palette(argv[1]);if(palette.colors.isEmpty())return 3;
    QTemporaryDir tmp;
    QString program="import os,json; print('\\033[31mANSI_OK Ω\\033[0m',flush=True); value=input(); print('INPUT:'+value,flush=True); open('result.json','w').write(json.dumps({'tty':os.isatty(0),'input':value,'cols':os.get_terminal_size().columns,'rows':os.get_terminal_size().lines,'cwd':os.getcwd()}))";
    TerminalWindow window(palette,argv[1],tmp.path(),{"python","-c",program});window.show();int initialColumns=window.current()->screenColumnsCount();
    QTermWidget *term=window.current();QString output;
    QObject::connect(term,&QTermWidget::receivedData,&app,[&](const QString &text){output+=QString::fromUtf8(text.toLatin1());});
    QTimer::singleShot(120,&app,[&]{window.resize(650,400);});
    QTimer::singleShot(300,&app,[&]{QApplication::clipboard()->setText("susnix-paste");term->pasteClipboard();});
    QTimer::singleShot(500,&app,[&]{term->sendText("\r");});
    // Keep the event loop alive even when the command's tab closes.
    app.setQuitOnLastWindowClosed(false);
    QTimer::singleShot(1000,&app,[&]{auto result=Palette::read(tmp.path()+"/result.json");bool ok=result["tty"].toBool()&&result["input"].toString()=="susnix-paste"&&result["cols"].toInt()>20&&result["cols"].toInt()<initialColumns&&result["rows"].toInt()>10&&result["cwd"].toString()==tmp.path()&&output.contains("ANSI_OK")&&output.contains(QString::fromUtf8("Ω"));if(!ok)fprintf(stderr,"Result: %s\nOutput: %s\n",QJsonDocument(result).toJson().constData(),output.toUtf8().constData());fprintf(stdout,"PTY / clipboard / Unicode / resize: %s\n",ok?"PASS":"FAIL");app.exit(ok?0:1);});
    return app.exec();
}
