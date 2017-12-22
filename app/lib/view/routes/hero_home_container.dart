import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:heroes_companion/models/hero_filter.dart';
import 'package:heroes_companion/redux/actions/actions.dart';
import 'package:heroes_companion/routes.dart';
import 'package:heroes_companion/view/common/hero_list_item.dart';
import 'package:heroes_companion/view/routes/hero_detail_container.dart';
import 'package:redux/redux.dart';

import 'package:heroes_companion_data/heroes_companion_data.dart';

import 'package:heroes_companion/redux/selectors/selectors.dart';
import 'package:heroes_companion/view/common/hero_list.dart';
import 'package:heroes_companion/redux/state.dart';
import 'package:heroes_companion/services/heroes_service.dart';

class HeroHome extends StatelessWidget {
  HeroHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, vm) {
      return new Scaffold(
        appBar: new AppBar(title: new Text('Heroes Companion')),
        body: new HeroList(
          vm.heroes,
          onTap: vm.onTap,
          onLongPress: vm.onLongPress,
        ),
        floatingActionButton: new FloatingActionButton(
            child: new Icon(Icons.search),
            onPressed: () => Navigator.of(context).pushNamed(Routes.search),
            backgroundColor: Theme.of(context).accentColor,
          ),
        bottomNavigationBar: new BottomNavigationBar(
          currentIndex: vm.currentFilter.index,
          items: [
            new BottomNavigationBarItem(
              icon: new Icon(Icons.all_inclusive),
              title: new Text('All')
            ),
            new BottomNavigationBarItem(
              icon: new Icon(Icons.favorite),
              title: new Text('Favorite')
            )
          ],
          onTap: (index) => vm.bottomNavTap(index),
        )
      );
      },
    );
  }
}

class _ViewModel {
  final List<Hero> heroes;
  final bool loading;
  final HeroFilter currentFilter;
  final dynamic onLongPress;
  final dynamic bottomNavTap;
  final dynamic onTap = (BuildContext context, HeroListItem heroListItem) {
    Navigator.of(context).push(new PageRouteBuilder(
          pageBuilder: (context, a1, a2) => new HeroDetailContainer(
              heroListItem.hero.heroes_companion_hero_id),
        ));
  };

  _ViewModel({@required this.heroes, @required this.loading, this.onLongPress, this.bottomNavTap, this.currentFilter});

  static _ViewModel fromStore(Store<AppState> store) {
    final dynamic _favorite = (BuildContext context, HeroListItem item) {
      item.hero.is_favorite
          ? unFavorite(store, item.hero)
          : setFavorite(store, item.hero);
    };

    final dynamic _bottomNavTap = (int index) {
      HeroFilter filter = HeroFilter.values.firstWhere( (v) => v.index == index, orElse: () => HeroFilter.all);
      store.dispatch(new SetFilterAction(filter));
    };

    return new _ViewModel(
      heroes: heroesbyFilterSelector(store.state),
      loading: store.state.isLoading,
      onLongPress: _favorite,
      bottomNavTap: _bottomNavTap,
      currentFilter: filterSelector(store.state)
    );
  }
}
