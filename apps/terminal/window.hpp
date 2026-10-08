#pragma once
#include "palette.hpp"
#include <qtermwidget.h>
#include <QApplication>
#include <QClipboard>
#include <QDesktopServices>
#include <QFontDatabase>
#include <QHBoxLayout>
#include <QLabel>
#include <QMessageBox>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QProcessEnvironment>
#include <QProcess>
#include <QSaveFile>
#include <QScreen>
#include <QShortcut>
#include <QStackedWidget>
#include <QTabBar>
#include <QToolButton>
#include <QWindow>
#include <QDateTime>
#include <QCryptographicHash>

class TerminalFrame : public QWidget {
public:
    Palette &palette;
    explicit TerminalFrame(Palette &p,QWidget *parent=nullptr):QWidget(parent),palette(p){}
    void mousePressEvent(QMouseEvent *e) override {
        if(e->button()==Qt::LeftButton&&windowHandle()&&!isMaximized()){
            Qt::Edges edges;const auto point=e->position();
            if(point.x()<10)edges|=Qt::LeftEdge;else if(point.x()>width()-10)edges|=Qt::RightEdge;
            if(point.y()<10)edges|=Qt::TopEdge;else if(point.y()>height()-10)edges|=Qt::BottomEdge;
            if(edges&&windowHandle()->startSystemResize(edges))return;
        }
        QWidget::mousePressEvent(e);
    }
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);p.setRenderHint(QPainter::Antialiasing);
        const qreal w=width()-2,h=height()-2,c=12;
        QPainterPath edge;edge.moveTo(c+1,1);edge.lineTo(w-c,1);edge.lineTo(w,c);edge.lineTo(w,h-c);edge.lineTo(w-c,h);edge.lineTo(c,h);edge.lineTo(1,h-c);edge.lineTo(1,c);edge.closeSubpath();
        p.fillPath(edge,palette.color("background",palette.effect("opacityGlass",.9)));
        QLinearGradient glow(0,0,w,h);glow.setColorAt(0,palette.color("primary",.65));glow.setColorAt(.55,palette.color("border",.45));glow.setColorAt(1,palette.color("accent",.7));
        for(int thickness:{5,3,1}) {p.setOpacity(thickness==1?1:.08);p.setPen(QPen(QBrush(glow),thickness));p.drawPath(edge);}p.setOpacity(1);
        p.setPen(QPen(palette.color("primary",.4),1));p.drawLine(12,42,width()-12,42);p.drawLine(12,height()-27,width()-12,height()-27);
        // Static corner facets, no continuously running decorative animation.
        p.setPen(QPen(palette.color("primary",.9),1));p.drawLine(4,19,19,4);p.drawLine(4,height()-19,19,height()-4);
        p.setPen(QPen(palette.color("accent",.85),1));p.drawLine(width()-19,4,width()-4,19);p.drawLine(width()-19,height()-4,width()-4,height()-19);
    }
};
class Header : public QWidget {
public:
    using QWidget::QWidget;
    void mousePressEvent(QMouseEvent *e) override {if(e->button()==Qt::LeftButton&&window()->windowHandle())window()->windowHandle()->startSystemMove();}
    void mouseDoubleClickEvent(QMouseEvent *e) override {if(e->button()==Qt::LeftButton){if(window()->isMaximized())window()->showNormal();else window()->showMaximized();}}
};
class TechTabs : public QTabBar {
public:
    Palette &palette;
    explicit TechTabs(Palette &p):palette(p){setExpanding(false);setTabsClosable(false);setMovable(false);setDrawBase(false);}
    QSize tabSizeHint(int) const override {return QSize(156,28);}
    void mousePressEvent(QMouseEvent *e) override {
        QTabBar::mousePressEvent(e);
        if(e->button()==Qt::LeftButton&&window()->windowHandle())window()->windowHandle()->startSystemMove();
    }
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);p.setRenderHint(QPainter::Antialiasing);
        for(int i=0;i<count();++i){auto r=tabRect(i).adjusted(2,2,-2,-1);bool active=i==currentIndex();
            QPainterPath shape;shape.moveTo(r.left(),r.bottom());shape.lineTo(r.left()+20,r.top());shape.lineTo(r.right()-20,r.top());shape.lineTo(r.right(),r.bottom());shape.closeSubpath();
            QLinearGradient glass(r.topLeft(),r.bottomLeft());glass.setColorAt(0,palette.color("primary",active?.16:.03));glass.setColorAt(1,palette.color("surface",.2));
            p.fillPath(shape,glass);p.setPen(QPen(palette.color(active?"primary":"border",active?.85:.5),1));p.drawPath(shape);
            p.setFont(font());p.setPen(palette.color(active?"text":"textMuted"));p.drawText(r.adjusted(27,0,-30,0),Qt::AlignVCenter|Qt::AlignLeft,QFontMetrics(font()).elidedText(tabText(i),Qt::ElideMiddle,r.width()-58));
        }
    }
};
class WindowControls : public QWidget {
public:
    Palette &palette;
    explicit WindowControls(Palette &p,QWidget *parent):QWidget(parent),palette(p) {setFixedSize(88,26);}
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);p.setRenderHint(QPainter::Antialiasing);
        QPainterPath outline;outline.moveTo(11,1);outline.lineTo(width()-17,1);outline.lineTo(width()-1,height()-1);outline.lineTo(1,height()-1);outline.lineTo(1,11);outline.closeSubpath();
        QLinearGradient edge(0,0,width(),0);edge.setColorAt(0,palette.color("primary",.8));edge.setColorAt(1,palette.color("secondary",.55));
        p.fillPath(outline,palette.color("surface",.3));p.setPen(QPen(QBrush(edge),1));p.drawPath(outline);
    }
};
class TerminalWindow : public TerminalFrame {
public:
    QString assets,initialDirectory;
    QStringList command;
    TechTabs *tabs;
    QStackedWidget *sessions;
    QLabel *clock,*footer,*aside,*brand,*slogan;
    int fontSize=11;
    explicit TerminalWindow(Palette &p,QString assetRoot,QString directory,QStringList execute):TerminalFrame(p),assets(std::move(assetRoot)),initialDirectory(std::move(directory)),command(std::move(execute)) {
        setWindowTitle("Susnix Terminal");setWindowIcon(QIcon::fromTheme("utilities-terminal"));
        setWindowFlags(Qt::Window|Qt::FramelessWindowHint);setAttribute(Qt::WA_TranslucentBackground);
        setMinimumSize(420,280);const auto bounds=QGuiApplication::primaryScreen()->availableGeometry();resize(qMin(1000,bounds.width()-48),qMin(640,bounds.height()-100));
        auto layout=new QVBoxLayout(this);layout->setContentsMargins(12,8,12,5);layout->setSpacing(0);
        auto header=new Header(this);header->setFixedHeight(34);
        auto h=new QHBoxLayout(header);h->setContentsMargins(5,0,5,0);h->setSpacing(8);
        auto controls=new WindowControls(palette,header);auto controlsLayout=new QHBoxLayout(controls);controlsLayout->setContentsMargins(4,1,8,1);controlsLayout->setSpacing(2);h->addWidget(controls);
        for(const auto &kind:QStringList{"×","−","□"}){auto b=button(kind,kind=="−"?"Minimize":kind=="□"?"Maximize / restore":"Close",controls);b->setObjectName(kind=="×"?"closeWindow":"windowButton");controlsLayout->addWidget(b);connect(b,&QToolButton::clicked,this,[this,kind]{if(kind=="−"){
            if(!qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE"))QProcess::execute("hyprctl",{"eval","hl.dispatch(hl.dsp.window.move({window=\"pid:"+QString::number(QCoreApplication::applicationPid())+"\",workspace=\"special:susnix-minimized\",follow=false}))"});
            else showMinimized();
        }else if(kind=="□"){if(isMaximized())showNormal();else showMaximized();}else close();});}
        brand=new QLabel("S U S N I X  //");brand->setObjectName("brand");h->addWidget(brand);
        tabs=new TechTabs(p);tabs->setMaximumWidth(550);h->addWidget(tabs,1);
        auto plus=button("+","New tab · Ctrl+Shift+T",header);h->addWidget(plus);connect(plus,&QToolButton::clicked,this,[this]{addTab();});
        h->addStretch();
        slogan=new QLabel("BUILD DIFFERENT");slogan->setObjectName("slogan");h->addWidget(slogan);
        layout->addWidget(header);
        auto body=new QWidget;auto bodyLayout=new QHBoxLayout(body);bodyLayout->setContentsMargins(12,14,12,10);bodyLayout->setSpacing(16);
        sessions=new QStackedWidget;bodyLayout->addWidget(sessions,1);
        aside=new QLabel("S A M E\n\nH U M A N\n\nD I F F E R E N T\n\nO S\n\n────");aside->setObjectName("aside");aside->setFixedWidth(120);aside->setAlignment(Qt::AlignVCenter|Qt::AlignLeft);bodyLayout->addWidget(aside);
        layout->addWidget(body,1);
        auto bottom=new QHBoxLayout;bottom->setContentsMargins(12,5,12,0);footer=new QLabel;footer->setObjectName("footer");bottom->addWidget(footer);bottom->addStretch();clock=new QLabel;clock->setObjectName("clock");bottom->addWidget(clock);layout->addLayout(bottom);
        connect(tabs,&QTabBar::currentChanged,this,[this](int i){sessions->setCurrentIndex(i);if(current())current()->setFocus();updateFooter();});
        connect(tabs,&QTabBar::tabCloseRequested,this,[this](int i){closeTab(i,true);});
        shortcut("Ctrl+Shift+T",[this]{addTab();});shortcut("Ctrl+Shift+W",[this]{closeTab(tabs->currentIndex(),true);});
        shortcut("Ctrl+Shift+C",[this]{if(current())current()->copyClipboard();});shortcut("Ctrl+Shift+V",[this]{if(current())current()->pasteClipboard();});
        shortcut("Ctrl+Shift+F",[this]{if(current())current()->toggleShowSearchBar();});
        shortcut("Ctrl+Shift+Plus",[this]{zoom(1);});shortcut("Ctrl+Shift+Equal",[this]{zoom(1);});shortcut("Ctrl+Shift+Minus",[this]{zoom(-1);});shortcut("Ctrl+Shift+0",[this]{fontSize=11;zoom(0);});
        shortcut("Ctrl+PageUp",[this]{tabs->setCurrentIndex((tabs->currentIndex()+tabs->count()-1)%tabs->count());});shortcut("Ctrl+PageDown",[this]{tabs->setCurrentIndex((tabs->currentIndex()+1)%tabs->count());});
        auto timer=new QTimer(this);timer->setInterval(1000);connect(timer,&QTimer::timeout,this,[this]{clock->setText(QDateTime::currentDateTime().toString("HH:mm:ss"));});timer->start();clock->setText(QDateTime::currentDateTime().toString("HH:mm:ss"));
        p.changed=[this]{applyTheme();};applyTheme();addTab();
    }
    QToolButton *button(const QString &text,const QString &tip,QWidget *parent){auto b=new QToolButton(parent);b->setText(text);b->setToolTip(tip);b->setFixedSize(24,24);b->setCursor(Qt::PointingHandCursor);return b;}
    void shortcut(const QString &keys,std::function<void()> action){auto key=new QShortcut(QKeySequence(keys),this);connect(key,&QShortcut::activated,this,std::move(action));}
    QTermWidget *current() const {return qobject_cast<QTermWidget*>(sessions->currentWidget());}
    QString shell() const {auto s=qEnvironmentVariable("SHELL","/bin/bash");return QFileInfo(s).isExecutable()?s:"/bin/bash";}
    void addTab(){
        QString directory=current()?QFileInfo("/proc/"+QString::number(current()->getShellPID())+"/cwd").canonicalFilePath():initialDirectory;
        if(directory.isEmpty())directory=initialDirectory;
        auto term=new QTermWidget(0);term->setHistorySize(10000);term->setScrollBarPosition(QTermWidgetInterface::ScrollBarRight);term->setMargin(4);term->setBlinkingCursor(false);term->setFlowControlEnabled(false);term->setFlowControlWarningEnabled(false);term->setConfirmMultilinePaste(true);term->setTerminalSizeHint(false);
        auto env=QProcessEnvironment::systemEnvironment();env.insert("TERM","xterm-256color");env.insert("COLORTERM","truecolor");env.insert("SUSNIX_TERMINAL_ASSETS",assets);env.insert("SUSNIX_PRIMARY",palette.color("primary").name());env.insert("SUSNIX_SECONDARY",palette.color("secondary").name());env.insert("SUSNIX_TEXT",palette.color("text").name());
        term->setEnvironment(env.toStringList());term->setWorkingDirectory(directory);
        
        bool executing=!command.isEmpty()&&sessions->count()==0;
        term->setShellProgram(executing?command.first():shell());
        term->setArgs(executing?command.mid(1):QFileInfo(shell()).fileName()=="bash"?QStringList{"--rcfile",assets+"/bashrc","-i"}:QStringList{"-i"});
        const int i=sessions->addWidget(term);tabs->addTab("~ : "+QFileInfo(executing?command.first():shell()).fileName());
        auto closeButton=button("×","Close tab",tabs);closeButton->setFixedSize(20,24);tabs->setTabButton(i,QTabBar::RightSide,closeButton);
        connect(closeButton,&QToolButton::clicked,this,[this,term]{closeTab(sessions->indexOf(term),true);});tabs->setCurrentIndex(i);
        connect(term,&QTermWidget::finished,this,[this,term]{int i=sessions->indexOf(term);if(i>=0)closeTab(i,false);});
        connect(term,&QTermWidget::titleChanged,this,[this,term]{int i=sessions->indexOf(term);if(i>=0){tabs->setTabText(i,term->title());setWindowTitle("Susnix Terminal — "+term->title());}});
        connect(term,&QTermWidget::currentDirectoryChanged,this,[this,term](const QString &dir){int i=sessions->indexOf(term);if(i>=0)tabs->setTabText(i,QFileInfo(dir).fileName()+" : "+QFileInfo(shell()).fileName());});
        connect(term,&QTermWidget::urlActivated,this,[](const QUrl &url,bool){if(url.scheme()=="http"||url.scheme()=="https")QDesktopServices::openUrl(url);});
        colorTerm(term);term->startShellProgram();term->setFocus();updateFooter();
    }
    bool busy(QTermWidget *term){return term&&term->getForegroundProcessId()>0&&term->getForegroundProcessId()!=term->getShellPID();}
    bool confirm(){return QMessageBox::question(this,"Close running program?","A program is still running in this terminal. Close it?",QMessageBox::Yes|QMessageBox::No,QMessageBox::No)==QMessageBox::Yes;}
    void closeTab(int i,bool check){if(i<0)return;auto term=qobject_cast<QTermWidget*>(sessions->widget(i));if(check&&busy(term)&&!confirm())return;tabs->removeTab(i);sessions->removeWidget(term);term->deleteLater();if(!tabs->count())close();else updateFooter();}
    void closeEvent(QCloseEvent *e) override {for(int i=0;i<sessions->count();++i)if(busy(qobject_cast<QTermWidget*>(sessions->widget(i)))){if(!confirm()){e->ignore();return;}break;}e->accept();}
    void resizeEvent(QResizeEvent *e) override {aside->setVisible(width()>950);brand->setVisible(width()>650);slogan->setVisible(width()>900);TerminalFrame::resizeEvent(e);}
    void zoom(int step){fontSize=qBound(7,fontSize+step,24);for(int i=0;i<sessions->count();++i)qobject_cast<QTermWidget*>(sessions->widget(i))->setTerminalFont(QFont("monospace",fontSize));}
    void updateFooter(){footer->setText("SUSNIX TERM  v1.0  |  WAYLAND  |  "+QFileInfo(shell()).fileName().toUpper()+"  |  "+palette.name.toUpper());}
    QString schemePath()const{return qEnvironmentVariable("XDG_CACHE_HOME",QDir::homePath()+"/.cache")+"/susnix/terminal-"+QString::fromLatin1(QCryptographicHash::hash(QJsonDocument(palette.colors).toJson(QJsonDocument::Compact),QCryptographicHash::Sha256).toHex().left(16))+".colorscheme";}
    void colorTerm(QTermWidget *term){term->setColorScheme(schemePath());term->setTerminalOpacity(palette.effect("opacityGlass",.9));term->setTerminalFont(QFont("monospace",fontSize));}
    void applyTheme(){
        QString scheme="[General]\nDescription=Susnix\nOpacity="+QString::number(palette.effect("opacityGlass",.9))+"\n";
        auto section=[&](const QString &name,const QString &role){auto c=palette.color(role);scheme+="["+name+"]\nColor="+QString::number(c.red())+","+QString::number(c.green())+","+QString::number(c.blue())+"\n";};
        section("Background","background");section("BackgroundIntense","background");section("Foreground","text");section("ForegroundIntense","text");
        const QStringList regular{"surface","danger","success","warning","primary","secondary","accent","textMuted"},bright{"border","danger","success","warning","primary","secondary","accent","text"};
        for(int i=0;i<8;++i){section("Color"+QString::number(i),regular[i]);section("Color"+QString::number(i)+"Intense",bright[i]);section("Color"+QString::number(i)+"Faint",regular[i]);}
        QDir().mkpath(QFileInfo(schemePath()).path());QSaveFile f(schemePath());if(f.open(QIODevice::WriteOnly)){f.write(scheme.toUtf8());f.commit();}
        QPalette native;native.setColor(QPalette::Window,palette.color("surfaceRaised"));native.setColor(QPalette::WindowText,palette.color("text"));native.setColor(QPalette::Base,palette.color("surface"));native.setColor(QPalette::Text,palette.color("text"));native.setColor(QPalette::Button,palette.color("surfaceRaised"));native.setColor(QPalette::ButtonText,palette.color("primary"));native.setColor(QPalette::Highlight,palette.color("secondary"));native.setColor(QPalette::HighlightedText,palette.color("text"));QApplication::setPalette(native);
        const auto primary=palette.color("primary").name(),muted=palette.color("textMuted").name(),text=palette.color("text").name();
        setStyleSheet(QString("QWidget { color:%1; } QLabel,QToolButton,QTabBar {font-family:monospace;font-size:12px;} QLabel#brand {color:%2;font-size:15px;font-weight:bold;} QLabel#slogan,QLabel#aside,QLabel#footer {color:%3;font-size:9px;} QLabel#clock {color:%2;font-size:12px;} QToolButton {border:0;background:transparent;color:%2;font-size:18px;} QToolButton:hover {background:%4;} QToolButton#closeWindow {color:"+palette.color("accent").name()+";} QTabBar::close-button {image:none;width:12px;height:12px;} QScrollBar:vertical {width:5px;background:transparent;} QScrollBar::handle:vertical {background:%3;min-height:20px;} QScrollBar::add-line:vertical,QScrollBar::sub-line:vertical {height:0;} QToolTip {background:%4;color:%1;border:1px solid %2;} QMessageBox {background:%4;}").arg(text,primary,muted,palette.color("surfaceRaised").name()));
        for(int i=0;i<sessions->count();++i)colorTerm(qobject_cast<QTermWidget*>(sessions->widget(i)));
        tabs->update();update();updateFooter();
    }
};
