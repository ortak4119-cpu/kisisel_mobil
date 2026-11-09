import 'package:flutter/widgets.dart';

/// Tablet/iPad uyumluluk yardımcıları.
///
/// Uygulama telefon için tasarlandı; geniş ekranlarda (iPad vb.) içerik tek
/// sütun halinde gereksiz yere yayılıp kenarlarda boşluk bırakmasın diye
/// içeriği ortalayıp makul bir genişliğe sınırlarız. Böylece iPad kullanıcısı
/// da kartları telefondaki gibi okunaklı boyutta görür.

/// Bu genişliğin üzerindeki ekranlar "tablet" sayılır.
const double kTabletBreakpoint = 600;

/// Geniş ekranda içeriğin ulaşabileceği en büyük genişlik.
const double kContentMaxWidth = 640;

/// Geniş ekranlarda (tablet/iPad) çocuğu yatayda ortalar ve en fazla
/// [maxWidth] genişliğe sınırlar. Telefonda ([maxWidth]'ten dar ekranlarda)
/// çocuğu hiç dokunmadan olduğu gibi döndürür; böylece telefon düzeni birebir
/// korunur, yalnızca büyük ekranlarda devreye girer.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= maxWidth) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
