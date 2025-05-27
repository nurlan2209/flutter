class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static List<CategoryModel> defaultCategories = [
    CategoryModel(id: 'food', name: 'Еда', icon: '🍔', color: '#FF6B6B'),
    CategoryModel(id: 'transport', name: 'Транспорт', icon: '🚗', color: '#4ECDC4'),
    CategoryModel(id: 'shopping', name: 'Покупки', icon: '🛍️', color: '#45B7D1'),
    CategoryModel(id: 'entertainment', name: 'Развлечения', icon: '🎬', color: '#96CEB4'),
    CategoryModel(id: 'bills', name: 'Счета', icon: '💡', color: '#FECA57'),
    CategoryModel(id: 'rent', name: 'Аренда', icon: '🏠', color: '#FF9FF3'),
    CategoryModel(id: 'healthcare', name: 'Здоровье', icon: '🏥', color: '#54A0FF'),
    CategoryModel(id: 'other', name: 'Другое', icon: '📌', color: '#A0A0A0'),
  ];
}