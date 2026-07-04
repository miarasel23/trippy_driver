class Car {
  final String uuid;
  final String carType;
  final int setCapacity;
  final String carAvatar;
  final num? minimumBookingPrice;
  final String? distance;
  final String? priceSetUuid;

  Car({
    required this.uuid,
    required this.carType,
    required this.setCapacity,
    required this.carAvatar,
    this.minimumBookingPrice,
    this.distance,
    this.priceSetUuid,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    num? minPrice;
    if (json['rent_calculation'] != null) {
      minPrice = json['rent_calculation']['minimum_booking_price'];
    } else {
      minPrice = json['minimum_booking_price'];
    }

    String? parsedDistance;
    if (json['distance'] is Map) {
      parsedDistance = json['distance']['total_km']?.toString();
    } else {
      parsedDistance = json['distance']?.toString();
    }

    String? priceSetUuid;
    if (json['price_sets'] != null && json['price_sets'] is List && (json['price_sets'] as List).isNotEmpty) {
      priceSetUuid = json['price_sets'][0]['uuid'];
    }

    return Car(
      uuid: json['uuid'],
      carType: json['car_type'],
      setCapacity: json['set_capacity'],
      carAvatar: json['car_avatar'],
      minimumBookingPrice: minPrice,
      distance: parsedDistance,
      priceSetUuid: priceSetUuid,
    );
  }
}

class ServiceGroup {
  final String serviceName;
  final String avatar;
  final List<Car> cars;

  ServiceGroup({
    required this.serviceName,
    required this.avatar,
    required this.cars,
  });

  factory ServiceGroup.fromJson(Map<String, dynamic> json) {
    return ServiceGroup(
      serviceName: json['service_name'],
      avatar: json['avatar'],
      cars: (json['cars'] as List).map((e) => Car.fromJson(e)).toList(),
    );
  }
}

class ServiceResponse {
  final Map<String, ServiceGroup> groups;

  ServiceResponse({required this.groups});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, ServiceGroup> services = {};

    (json['data'] as Map<String, dynamic>).forEach((key, value) {
      services[key] = ServiceGroup.fromJson(value);
    });

    return ServiceResponse(groups: services);
  }
}



// children: [
//         GestureDetector(
//           onTap: () {
//             showModalBottomSheet(
//               context: context,
//               isScrollControlled: true,
//               builder: (BuildContext context) {
//                 return FractionallySizedBox(
//                   heightFactor: 0.845,
//                   child: const ChooseCarBottomSheet(),
//                 );
//               },
//             );
//           },
//           child: serviceWidget(
//             icon: Icon(
//               Icons.car_crash,
//               size: 70,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: loc.translate('intercity'),
//             context: context,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {},
//           child: serviceWidget(
//             icon: Icon(
//               Icons.car_crash,
//               size: 70,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: loc.translate('hourly'),
//             context: context,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {},
//           child: serviceWidget(
//             icon: Icon(
//               Icons.car_crash,
//               size: 70,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: loc.translate('airport_rental'),
//             context: context,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {},
//           child: serviceWidget(
//             icon: Icon(
//               Icons.car_crash,
//               size: 70,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: loc.translate('return_trip'),
//             context: context,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {},
//           child: serviceWidget(
//             icon: Icon(
//               Icons.car_crash,
//               size: 70,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: loc.translate('ride_share'),
//             context: context,
//           ),
//         ),
//       ],