#pragma once
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileSystemWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTimer>
#include <functional>
#include <cmath>

// Same semantic palettes and override file as Quickshell; no widget-local colors.
class Palette : public QObject {
public:
    QJsonObject colors, effects;
    QString name = "Nyx", root, config;
    std::function<void()> changed;
    QFileSystemWatcher watcher;
    QTimer debounce;
    explicit Palette(QString assets) : root(std::move(assets)) {
        config = qEnvironmentVariable("XDG_CONFIG_HOME", QDir::homePath()+"/.config")+"/susnix";
        debounce.setSingleShot(true); debounce.setInterval(80);
        connect(&watcher,&QFileSystemWatcher::directoryChanged,this,[this]{debounce.start();});
        connect(&watcher,&QFileSystemWatcher::fileChanged,this,[this]{debounce.start();});
        connect(&debounce,&QTimer::timeout,this,[this]{load();});
        load();
    }
    static QJsonObject read(const QString &path) {
        QFile f(path); if(!f.open(QIODevice::ReadOnly)) return {};
        return QJsonDocument::fromJson(f.readAll()).object();
    }
    QColor color(const QString &role, qreal opacity=1) const {
        QColor result(colors.value(role).toString()); result.setAlphaF(opacity); return result;
    }
    double effect(const QString &key,double fallback) const {return effects.value(key).toDouble(fallback);}
    bool load() {
        const auto defaults=read(root+"/themes/Nyx.json");
        if(defaults.isEmpty())return false;
        auto settings=read(config+"/colors.json");
        if(QFile::exists(config+"/colors.json")&&settings.isEmpty())return false;
        const auto theme=settings.value("theme").toString("Nyx");
        if(!QStringList{"Nyx","Aurora","Void","Sakura","Terminal","Ember"}.contains(theme))return false;
        auto nextColors=defaults.value("colors").toObject();
        auto nextEffects=defaults.value("effects").toObject();
        const auto selected=read(root+"/themes/"+theme+".json");
        if(selected.isEmpty())return false;
        for(const auto &data:{selected,settings}) {
            if(data.contains("colors")&&!data.value("colors").isObject())return false;
            if(data.contains("effects")&&!data.value("effects").isObject())return false;
            auto overrides=data.value("colors").toObject();
            for(auto i=overrides.begin();i!=overrides.end();++i) {
                if(!nextColors.contains(i.key())||!QRegularExpression("^#[0-9a-fA-F]{6}$").match(i.value().toString()).hasMatch())return false;
                nextColors[i.key()]=i.value();
            }
            const auto fx=data.value("effects").toObject();
            for(auto i=fx.begin();i!=fx.end();++i){
                const double value=i.value().toDouble(-1);
                if(!nextEffects.contains(i.key())||!i.value().isDouble()||!std::isfinite(value)||value<0)return false;
                if(i.key().startsWith("opacity")||i.key()=="glowStrength"){if(value>1)return false;}
                else if(std::floor(value)!=value||value>1000)return false;
                nextEffects[i.key()]=value;
            }
        }
        const bool differs=colors!=nextColors||effects!=nextEffects||name!=theme;
        colors=nextColors;effects=nextEffects;name=theme;
        // Watch parent directories as well: the theme manager replaces files atomically.
        for(const auto &path:QStringList{config,config+"/colors.json",root+"/themes"})
            if(QFile::exists(path)&&!watcher.directories().contains(path)&&!watcher.files().contains(path))watcher.addPath(path);
        if(differs&&changed)changed();
        return true;
    }
};
