class Product {
  final String id;
  final String name;
  final String size;
  final String description;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.description,
    this.imageUrl,
  });
}
