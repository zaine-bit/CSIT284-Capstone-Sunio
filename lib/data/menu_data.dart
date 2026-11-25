import '../models/food_item.dart';

/// Sample data. Replace later with your real menu.
const categories = ['All', 'Meals', 'Snacks', 'Drinks'];

const menuItems = <FoodItem>[
  FoodItem(
    name: 'Chicken Adobo Rice',
    description: 'Garlic-soy chicken with steamed rice',
    price: 85,
    image: 'assets/images/menu_chicken_adobo.png',
    category: 'Meals',
    tag: 'Best seller',
  ),
  FoodItem(
    name: 'Pork Sisig Rice',
    description: 'Sizzling chopped pork, egg on top',
    price: 95,
    image: 'assets/images/menu_pork_sisig.png',
    category: 'Meals',
  ),
  FoodItem(
    name: 'Tapsilog',
    description: 'Beef tapa, garlic rice, fried egg',
    price: 90,
    image: 'assets/images/menu_tapsilog.png',
    category: 'Meals',
  ),
  FoodItem(
    name: 'Pancit Canton',
    description: 'Stir-fried noodles with vegetables',
    price: 55,
    image: 'assets/images/menu_pancit_canton.png',
    category: 'Meals',
  ),
  FoodItem(
    name: 'Siomai (4 pcs)',
    description: 'Steamed pork dumplings with chili',
    price: 40,
    image: 'assets/images/menu_siomai.png',
    category: 'Snacks',
    tag: 'New',
  ),
  FoodItem(
    name: 'Banana Cue',
    description: 'Caramelized saba banana on a stick',
    price: 20,
    image: 'assets/images/bananacue.png',
    category: 'Snacks',
  ),
  FoodItem(
    name: 'French Fries',
    description: 'Crispy, with ketchup',
    price: 45,
    image: 'assets/images/menu_french_fries.png',
    category: 'Snacks',
  ),
  FoodItem(
    name: 'Iced Tea',
    description: 'Cold, sweet, 16 oz',
    price: 30,
    image: 'assets/images/menu_iced_tea.png',
    category: 'Drinks',
  ),
  FoodItem(
    name: 'Calamansi Juice',
    description: 'Fresh-squeezed, lightly sweet',
    price: 30,
    image: 'assets/images/menu_calamansi_juice.png',
    category: 'Drinks',
  ),
  FoodItem(
    name: 'Bottled Water',
    description: '500 ml',
    price: 20,
    image: 'assets/images/menu_bottled_water.png',
    category: 'Drinks',
  ),
];
