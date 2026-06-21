class CarouselItem {
  const CarouselItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.buttonText,
    this.onTapAction,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? buttonText;
  final String? onTapAction;
}
