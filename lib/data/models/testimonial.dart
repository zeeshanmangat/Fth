class Testimonial {
  final String id;
  final String authorName;
  final String organization;
  final String quote;
  final double rating;
  final String stayType;
  final String date;

  const Testimonial({
    required this.id,
    required this.authorName,
    required this.organization,
    required this.quote,
    this.rating = 4.0,
    required this.stayType,
    required this.date,
  });
}
