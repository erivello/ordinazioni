enum DishCategory {
  primi,
  secondi,
  contorni,
  bevande,
  dessert,
}

extension DishCategoryExtension on DishCategory {
  String get name {
    switch (this) {
      case DishCategory.primi:
        return 'Primi Piatti';
      case DishCategory.secondi:
        return 'Secondi Piatti';
      case DishCategory.contorni:
        return 'Contorni';
      case DishCategory.bevande:
        return 'Bevande';
      case DishCategory.dessert:
        return 'Dessert';
    }
  }
}
