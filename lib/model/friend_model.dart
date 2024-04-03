class FriendModel {
  String uid;
  String? photo;
  String name;
  String? bio;

  FriendModel({
    required this.uid,
    this.photo,
    required this.name,
    this.bio,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      uid: json['uid'],
      photo: json['photo'],
      name: json['name'],
      bio: json['bio'],
    );
  }
}
