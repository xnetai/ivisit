class Contact {
  final String firstName;
  final String lastName;

  Contact({required this.firstName, required this.lastName});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}


