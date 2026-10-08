#include <QCoreApplication>
#include <QImage>
#include <QtMath>
// A single low-resolution blur snapshot; no frame loop or GPU shader dependency.
int main(int argc,char **argv){
    QCoreApplication app(argc,argv);if(argc!=3)return 2;
    QImage image(QString::fromLocal8Bit(argv[1]));if(image.isNull())return 1;
    const QSize small(qMax(1,image.width()/8),qMax(1,image.height()/8));
    image=image.scaled(small,Qt::KeepAspectRatio,Qt::SmoothTransformation)
        .scaled(image.size(),Qt::IgnoreAspectRatio,Qt::SmoothTransformation);
    return image.save(QString::fromLocal8Bit(argv[2]),"PNG")?0:1;
}
