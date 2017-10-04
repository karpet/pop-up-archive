;(function(){
angular.module('Directory.collections.models', ['RailsModel', 'Directory.imageFiles.models'])
.factory('Collection', ['Model', 'Item', 'ImageFile', function (Model, Item, ImageFile) {
  var collections = {};


  var Collection = Model({url:'/api/collections/{{id}}', name: 'collection', only: ['title', 'description', 'itemsVisibleByDefault', 'copyMedia', 'storage']});

  var PublicCollection = Model({url:'/api/collections/public', name:'collection'});
  Collection.public = function () {
    return PublicCollection.query.apply(PublicCollection, arguments);
  }

  Collection.prototype.addImageFile = function (file, options ){
    var options = options || {};
    var collection = this;
    var originalFileUrl = null;
    if (angular.isDefined(file.url)) {
      originalFileUrl = file.url;
    }
    var imageFile = new ImageFile({container: "collections", containerId: collection.id, originalFileUrl: originalFileUrl});

    imageFile.create().then( function() {
      imageFile.filename = imageFile.cleanFileName(file.name);      
      collection.imageFiles = collection.imageFiles || [];
      collection.imageFiles.push(imageFile);
      options.token = collection.token;
      imageFile.upload(file, options);
    });
    return imageFile;
  }


  Collection.prototype.getThumbImage = function() {
    var self = this;
    if (self.imageFiles.length) {
      // first url from last image
      return self.imageFiles.slice(-1)[0].url.thumb[0];
    } 
    return null; // TODO generic PUA image?
  }

  Collection.prototype.fetchItems = function () {
    var self = this;
    Item.get({collectionId: this.id}).then(function (items) {
      self.items = items;
      angular.forEach(items, function (item) {
        item.getCollection = function () {
          return self;
        }
      });
      return items;
    });
    return this;
  }

  Collection.prototype.link = function () {
    return "/collections/" + this.id; 
  }

  Collection.prototype.visibilityIsSet = function () {
    return this.id || this.itemsVisibleByDefault === false || this.itemsVisibleByDefault;
  }

  Collection.prototype.privateOrPublic = function () {
    if ((this.storage == "InternetArchive") && this.itemsVisibleByDefault)
      return 'public (archive.org)';

    return this.itemsVisibleByDefault ? 'public' : 'private';
  }

  Collection.prototype.getThumbClass = function () {
    return "icon-inbox"
  }

  // Collection.attrAccessible = ['title', 'description', 'itemsVisibleByDefault'];

  return Collection;
}])
.filter('publicCollections', function () {
  var pub = [];
  return buildCollectionFilter(true, pub);
})
.filter('privateCollections', function() {
  var pvt = [];
  return buildCollectionFilter(false, pvt);
})
.filter('validChangeCollections', ['Me', function (Me) {
  Me.authenticated(function (currentUser) {
    user = currentUser;
  });
  return function (collections, item, Model) {
    cols = user.collections
    collections = []
    for (var key in cols)  {
      obj = {}
      obj["id"] = key
      obj["title"] = cols[key]
      collections.push(obj)
      console.log(obj)
    }
    
    return collections;
  };
}])
.filter('notUploads', ['Me', function (Me) {
  var user = {};
  var c = [];
  Me.authenticated(function (currentUser) {
    user = currentUser;
  });
  return function (collections) {
    if (angular.isArray(collections)) {
      c.splice(0, c.length);
      angular.forEach(collections, function (collection, index) {
        c.push(collection);
      });
      return c;
    } else {
      return collections;
    }
  };
}]);

function buildCollectionFilter(visible, array) {
  return function(collections) {
    if (angular.isArray(collections)) {
      array.splice(0, array.length);
      angular.forEach(collections, function(collection) {
        if (collection.itemsVisibleByDefault == visible) {
          array.push(collection);
        }
      });
      return array
    } else {
      return collections;
    }
  };
}
})();
