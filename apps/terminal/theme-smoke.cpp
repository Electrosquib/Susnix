#include "palette.hpp"
#include <QCoreApplication>
#include <QSaveFile>
#include <QTemporaryDir>
#include <cstdio>
int main(int argc,char**argv){
    QCoreApplication app(argc,argv);if(argc!=2)return 2;
    QTemporaryDir directory;qputenv("XDG_CONFIG_HOME",directory.path().toUtf8());QDir().mkpath(directory.path()+"/susnix");
    QString config=directory.path()+"/susnix/colors.json";
    auto write=[&](QByteArray data){QSaveFile file(config);if(!file.open(QIODevice::WriteOnly)||file.write(data)!=data.size()||!file.commit())app.exit(2);};
    write("{\"theme\":\"Nyx\"}");Palette palette(argv[1]);int changes=0;
    palette.changed=[&]{++changes;};
    QTimer::singleShot(10,&app,[&]{write("{\"theme\":\"Sakura\"}");});
    QTimer::singleShot(250,&app,[&]{if(palette.name!="Sakura"){app.exit(1);return;}write("{\"theme\":\"Sakura\",\"colors\":{\"primary\":\"invalid\"}}");});
    QTimer::singleShot(500,&app,[&]{if(palette.name!="Sakura"){app.exit(1);return;}write("{\"theme\":\"Sakura\",\"effects\":{\"opacityGlass\":9}}");});
    QTimer::singleShot(750,&app,[&]{auto expected=Palette::read(QString(argv[1])+"/themes/Sakura.json").value("colors").toObject().value("primary").toString();bool ok=changes==1&&palette.color("primary").name().compare(expected,Qt::CaseInsensitive)==0;fprintf(stdout,"Atomic theme reload / invalid settings retention: %s\n",ok?"PASS":"FAIL");app.exit(ok?0:1);});
    return app.exec();
}
