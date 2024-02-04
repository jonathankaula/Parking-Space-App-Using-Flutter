import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:location/location.dart' as location_;
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCbtiG_Qxlsdn4TwxczCAsr5nxUcXmm2n4",
      projectId: "my-final-proj",
      storageBucket: "my-final-proj.appspot.com",
      messagingSenderId: "1079052974288",
      appId: "1:1079052974288:android:9b788db27bc25f85d186d5",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking space',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home:
          const UserTypeSelection(), // Set UserTypeSelection as the initial page
    );
  }
}

class UserTypeSelection extends StatelessWidget {
  const UserTypeSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Type Selection'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _navigateToLoginSignupPage(context, UserType.Driver);
            },
            child: const Text('I am a Driver'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _navigateToLoginSignupPage(
                  context, UserType.ParkingSpaceOperator);
            },
            child: const Text('I am a Parking Space Operator'),
          ),
        ],
      ),
    );
  }

  void _navigateToLoginSignupPage(BuildContext context, UserType userType) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginSignupPage(userType: userType),
      ),
    );
  }
}

enum UserType {
  Driver,
  ParkingSpaceOperator,
}

class ParkingSpaceOperatorPage extends StatefulWidget {
  const ParkingSpaceOperatorPage({Key? key}) : super(key: key);

  @override
  _ParkingSpaceOperatorPageState createState() =>
      _ParkingSpaceOperatorPageState();
}

class _ParkingSpaceOperatorPageState extends State<ParkingSpaceOperatorPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Space Operator Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserTypeSelection(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Parking Lot Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _availabilityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Availability'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _addParkingLotDetails();
              },
              child: const Text('Add Parking Lot Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _addParkingLotDetails() {
    try {
      // Get values from controllers
      String name = _nameController.text;
      String location = _locationController.text;
      int capacity = int.parse(_capacityController.text);
      int availability = int.parse(_availabilityController.text);

      // Create ParkingLot object
      ParkingLot parkingLot = ParkingLot(
        name: name,
        address: location,
        capacity: capacity,
        availability: availability,
      );
      print(parkingLot.name);
      // Add parking lot details to the database
      FirestoreService().addParkingLotDetails(parkingLot);

      // Clear text controllers
      _nameController.clear();
      _locationController.clear();
      _capacityController.clear();
      _availabilityController.clear();
    } catch (e) {
      print('Error adding parking lot details: $e');
    }
  }
}

class MapPage extends StatefulWidget {
  final UserType userType;

  const MapPage({Key? key, required this.userType}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addParkingLotDetails(ParkingLot parkingLot) async {
    try {
      await _firestore.collection('parkingLots').add(parkingLot.toMap());
    } catch (e) {
      print('Error adding parking lot details: $e');
    }
  }

  Future<List<ParkingLot>> getParkingLots() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('parkingLots').get();
      return querySnapshot.docs
          .map((doc) => ParkingLot.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving parking lot details: $e');
      return [];
    }
  }
}

class _MapPageState extends State<MapPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();
  final places =
      GoogleMapsPlaces(apiKey: 'AIzaSyC1irGIOZQJp0cYH8YDfPd3da83D9prfUI');
  final directions =
      GoogleMapsDirections(apiKey: 'AIzaSyC1irGIOZQJp0cYH8YDfPd3da83D9prfUI');
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestore = FirestoreService(); // Create an instance
  Set<Marker> _markers = {};
  User? currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserTypeSelection(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Handle opening a menu or showing user details here
              _showUserDetailsDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: const LatLng(37.7749, -122.4194),
              zoom: 12,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text('Welcome, ${currentUser?.displayName ?? "User"}!'),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search for a place',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchPlace(),
                    ),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     setState(() {}); // Force a rebuild
                    //   },
                    //   child: const Text('Force Rebuild'),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${currentUser?.displayName ?? "User"}'),
              Text('Email: ${currentUser?.email ?? ""}'),
              // Add more user details as needed
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentUser() async {
    currentUser = _auth.currentUser;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getCurrentUserLocation();
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      location_.Location locationService = location_.Location();
      location_.LocationData currentLocation =
          await locationService.getLocation();

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('userLocation'),
            position:
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
            infoWindow: const InfoWindow(
              title: 'Current Location',
            ),
          ),
        );
      });

      GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Error in _getCurrentUserLocation: $e');
    }
  }

  Future<void> _searchPlace() async {
    // try {
    // Get the search query from the text controller
    String query = _searchController.text;
    print('Search query: $query');
    // Use the places API to search for places
    PlacesSearchResponse response = await places.searchByText(
      query,
      language: 'en',
      location: Location(
        lat:
            37.7749, // Initial map location, you can update this based on the user's current location
        lng: -122.4194,
      ),
      radius: 10000, // Search radius in meters
    );
    print('Response: $response.results');
    // // Clear existing markers
    setState(() {
      _markers.clear();
    });

    // Add new markers based on the search results
    if (response.isOkay && response.results != null) {
      for (var result in response.results) {
        double lat = result.geometry!.location.lat;
        double lng = result.geometry!.location.lng;
        print('Lstitude: $lat');
        print('Lstitude: $lng');
        // Create a Marker for each search result
        Marker marker = Marker(
          markerId: MarkerId(result.placeId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: result.name,
            snippet: result.formattedAddress,
          ),
          onTap: () {
            _displayParkingLotDetails(result);
          },
        );

        // Add the marker to the set
        setState(() {
          _markers.add(marker);
        });
      }

      LatLngBounds _getBoundsForMarkers(Set<Marker> markers) {
        double? maxLat;
        double? minLat;
        double? maxLng;
        double? minLng;

        for (var marker in markers) {
          final position = marker.position;
          if (maxLat == null || position.latitude > maxLat) {
            maxLat = position.latitude;
          }
          if (minLat == null || position.latitude < minLat) {
            minLat = position.latitude;
          }
          if (maxLng == null || position.longitude > maxLng) {
            maxLng = position.longitude;
          }
          if (minLng == null || position.longitude < minLng) {
            minLng = position.longitude;
          }
        }

        return LatLngBounds(
          northeast: LatLng(maxLat!, maxLng!),
          southwest: LatLng(minLat!, minLng!),
        );
      }

      LatLngBounds bounds = _getBoundsForMarkers(_markers);
      // Get controller after markers added
      GoogleMapController controller = await _controller.future;

      // Animate camera to fit bounds
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
    // } catch (e) {
    //   print('Error in _searchPlace: $e');
    // }
    //}

    // Navigate to the parking lot details page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) =>
    //         ParkingLotDetailsPage(parkingLot: selectedParkingLot),
    //   ),
    // );
  }

  Future<void> _displayParkingLotDetails(PlacesSearchResult parkingLot) async {
    // Retrieve parking lot details from Firestore
    List<ParkingLot> parkingLots = await _firestore.getParkingLots();

    // Find the selected parking lot in the list
    ParkingLot selectedParkingLot = parkingLots.firstWhere(
      (lot) =>
          lot.name == parkingLot.name &&
          lot.address == parkingLot.formattedAddress,
      orElse: () =>
          ParkingLot(name: '', address: '', capacity: 0, availability: 0),
    );
  }

  // ... (existing code)

  Future<void> _getDirections(double destLat, double destLng) async {
    final currentLocation = await _getCurrentLocation();

    final directionsResponse = await directions.directionsWithLocation(
        Location(
            lat: currentLocation.latitude!, lng: currentLocation.longitude!),
        Location(lat: destLat, lng: destLng),
        travelMode: TravelMode.driving);

    if (directionsResponse.isOkay) {
      final steps = directionsResponse.routes!.first!.legs!.first!.steps;
      // Display steps on screen
      print('Steps: $steps');
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    final controller = await _controller.future;
    final LatLngBounds visibleRegion = await controller.getVisibleRegion();
    final LatLng center = LatLng(
      (visibleRegion.southwest.latitude + visibleRegion.northeast.latitude) / 2,
      (visibleRegion.southwest.longitude + visibleRegion.northeast.longitude) /
          2,
    );
    return center;
  }
}

class ParkingLotDetailsPage extends StatelessWidget {
  final ParkingLot parkingLot;

  const ParkingLotDetailsPage({Key? key, required this.parkingLot})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement UI to display parking lot details
    return Scaffold(
      appBar: AppBar(
        title: Text(parkingLot.name),
      ),
      body: Column(
        children: [
          Text('Name: ${parkingLot.name}'),
          Text('Address: ${parkingLot.address}'),
          Text(
              'Capacity: ${parkingLot.capacity.toString()}'), // Display capacity
          Text('Availability: ${parkingLot.availability.toString()}'),
          // Add more details as needed
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final UserType userType;

  const LoginPage({Key? key, required this.userType}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showNameField = true;

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _signIn(BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Remove the TextField for entering the name after successful login
      setState(() {
        _showNameField = false;
      });

      _navigateAfterLogin(context);
    } catch (e) {
      print('Login failed. Error: $e');
      _showErrorSnackbar('Login failed. Error: $e');
    }
  }

  void _signUp(BuildContext context) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the current user
      User? user = _auth.currentUser;

      // Set the display name
      await user?.updateProfile(displayName: _nameController.text);

      _navigateAfterLogin(context);
    } catch (e) {
      print('Sign up failed. Error: $e');
      _showErrorSnackbar('Sign up failed. Error: $e');
    }
  }

  void _navigateAfterLogin(BuildContext context) {
    if (widget.userType == UserType.Driver) {
      // Navigate driver to map page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(userType: UserType.Driver),
        ),
      );
    } else if (widget.userType == UserType.ParkingSpaceOperator) {
      // Navigate operator to operator page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParkingSpaceOperatorPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.userType == UserType.Driver && _showNameField)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.userType == UserType.Driver && _showNameField) {
                  // User is signing up, perform signup
                  _signUp(context);
                } else {
                  // User is logging in, perform login
                  _signIn(context);
                }
              },
              child: widget.userType == UserType.Driver
                  ? const Text('Sign Up')
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const SignupPage({
    Key? key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
  }) : super(key: key);

  void _signUp(BuildContext context) async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Get the current user
      User? user = _auth.currentUser;

      // Set the display name
      await user?.updateProfile(displayName: nameController.text);

      // Navigate to the appropriate page after signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(userType: UserType.Driver),
          // Assuming you want to navigate to the MapPage for the driver, adjust accordingly
        ),
      );
    } catch (e) {
      print('Sign up failed. Error: $e');
      // Handle signup failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Call the signup function
                _signUp(context);
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class ParkingLot {
  final String name;
  final String address;
  final int capacity; // New field
  final int availability; // New field

  ParkingLot({
    required this.name,
    required this.address,
    required this.capacity,
    required this.availability,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'capacity': capacity,
      'availability': availability,
    };
  }

  factory ParkingLot.fromMap(Map<String, dynamic> map) {
    return ParkingLot(
      name: map['name'],
      address: map['address'],
      capacity: map['capacity'] ?? 0,
      availability: map['availability'] ?? 0,
    );
  }
}

class LoginSignupPage extends StatefulWidget {
  final UserType userType;

  const LoginSignupPage({Key? key, required this.userType}) : super(key: key);

  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showNameField = false;

  void _toggleShowNameField() {
    setState(() {
      _showNameField = !_showNameField;
    });
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _authenticate(BuildContext context) async {
    try {
      if (_showNameField) {
        // Perform signup
        await _signUp();
      } else {
        // Perform login
        await _signIn();
      }

      // Navigate after successful login/signup
      _navigateAfterLogin(context);
    } catch (e) {
      print('Authentication failed. Error: $e');
      _showErrorSnackbar('Authentication failed. Error: $e');
    }
  }

  Future<void> _signIn() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _signUp() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    // Set the display name
    await user?.updateProfile(displayName: _nameController.text);
  }

  void _navigateAfterLogin(BuildContext context) {
    if (widget.userType == UserType.Driver) {
      // Navigate driver to map page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(userType: UserType.Driver),
        ),
      );
    } else if (widget.userType == UserType.ParkingSpaceOperator) {
      // Navigate operator to operator page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParkingSpaceOperatorPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showNameField
            ? const Text('Sign Up Page')
            : const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showNameField)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Call the authenticate function
                _authenticate(context);
              },
              child:
                  _showNameField ? const Text('Sign Up') : const Text('Login'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _toggleShowNameField,
              child: _showNameField
                  ? const Text('Already have an account? Login')
                  : const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
