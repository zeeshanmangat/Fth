import '../models/testimonial.dart';

class TestimonialRepository {
  static List<Testimonial> getTestimonials() {
    return const [
      Testimonial(
        id: 't-1',
        authorName: 'Mr. L. Damore',
        organization: '2 Sonns Enterprise',
        quote:
            'Testimonials provide a sense of what it\'s like to work with you, or what it\'s like to use your products and services. Family Transit Home delivers reliable, clean, and secure accommodation every time we visit Port Moresby.',
        rating: 4.0,
        stayType: 'Corporate Transit Stay',
        date: 'Verified Guest',
      ),
      Testimonial(
        id: 't-2',
        authorName: 'Sarah K. & Family',
        organization: 'Transit Travelers from Lae',
        quote:
            'Being just 5 minutes from Jacksons Airport made our early morning international flight completely stress-free. The airport shuttle was right on time and the kitchen had everything we needed.',
        rating: 4.0,
        stayType: 'Family Vacation',
        date: 'Verified Guest',
      ),
      Testimonial(
        id: 't-3',
        authorName: 'David M.',
        organization: 'Mining & Logistics Consultant',
        quote:
            'The 24/7 gated security, backup generator, and fast Wi-Fi make this my default stopover choice in Port Moresby. Very clean and excellent hospitality.',
        rating: 4.0,
        stayType: 'Extended Business Stay',
        date: 'Verified Guest',
      ),
    ];
  }
}
