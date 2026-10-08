#include "window.hpp"
#include <QCommandLineParser>
#include <cstdio>
#include <QStandardPaths>
int main(int argc,char **argv){
    QApplication app(argc,argv);QApplication::setApplicationName("susnix-terminal");QApplication::setDesktopFileName("susnix-terminal");
    QCommandLineParser args;args.setApplicationDescription("Susnix cyberpunk terminal");args.addHelpOption();
    args.addOption({"assets","Installed terminal assets directory","path",QDir::homePath()+"/.local/share/susnix-terminal"});
    args.addOption({"working-directory","Start in this directory","path",QDir::currentPath()});
    args.addOption({"check-theme","Validate the configured theme without opening a window"});
    args.addPositionalArgument("command","Program and arguments after -- (otherwise starts your shell)","[-- command ...]");args.process(app);
    Palette palette(args.value("assets"));if(palette.colors.isEmpty()){fprintf(stderr,"Susnix terminal: missing or invalid palette assets\n");return 1;}
    if(args.isSet("check-theme"))return 0;
    const QString cwd=args.value("working-directory");if(!QFileInfo(cwd).isDir()){fprintf(stderr,"Susnix terminal: working directory does not exist\n");return 2;}
    auto command=args.positionalArguments();
    if(!command.isEmpty()){
        QString executable=QStandardPaths::findExecutable(command.first());
        if(executable.isEmpty()){fprintf(stderr,"Susnix terminal: command not found\n");return 127;}command[0]=executable;
    }
    TerminalWindow window(palette,args.value("assets"),cwd,command);window.show();return app.exec();
}
