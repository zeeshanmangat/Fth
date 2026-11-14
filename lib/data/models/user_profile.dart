class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final int totalStays;
  final int loyaltyPoints;
  final String avatarUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.organization = '2 Sonns Enterprise / Independent Guest',
    this.totalStays = 3,
    this.loyaltyPoints = 450,
    this.avatarUrl = '',
  });
}
