// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    event UserCreated(
        address indexed userAddress,
        uint256 userId,
        string username,
        uint8 accountType
    );
    event StoreCreated(
        address indexed sellerAddress,
        uint256 storeId,
        string storeName,
        int256 latitude,
        int256 longitude
    );

    event OfferAccepted(
        uint256 indexed offerId,
        address indexed buyerAddress,
        bool isAccepted
    );
    event RequestCreated(
        uint256 indexed requestId,
        address indexed buyerAddress,
        string requestName,
        int256 latitude,
        int256 longitude,
        string[] images,
        uint8 lifecycle,
        string description,
        uint256 buyerId,
        uint256[] sellerIds,
        int256 sellersPriceQuote,
        uint256 lockedSellerId,
        uint256 createdAt,
        uint256 updatedAt
    );

    event OfferCreated(
        uint256 indexed offerId,
        address indexed sellerAddress,
        string storeName,
        int256 price,
        uint256 requestId,
        string[] images,
        uint256 sellerId
    );

    event RequestAccepted(
        uint256 indexed requestId,
        uint256 indexed offerId,
        uint256 indexed sellerId,
        uint256 updatedAt
    );

    event OfferRemoved(uint256 indexed offerId, address indexed sellerAddress);

    enum AccountType {
        BUYER,
        SELLER
    }
    enum RequestLifecycle {
        PENDING,
        ACCEPTED_BY_SELLER,
        ACCEPTED_BY_BUYER,
        REQUEST_LOCKED,
        COMPLETED
    }

    struct Location {
        int256 latitude;
        int256 longitude;
    }

    struct Store {
        uint256 id;
        string name;
        string description;
        Location location;
    }

    mapping(address => mapping(uint256 => Store)) public userStores;
    mapping(address => uint256[]) public userStoreIds;

    struct User {
        uint256 id;
        string username;
        string phone;
        Location location;
        uint256 createdAt;
        AccountType accountType;
    }

    struct Request {
        uint256 id;
        string name;
        uint256 buyerId;
        int256 sellersPriceQuote;
        uint256[] sellerIds;
        uint256[] offerIds;
        uint256 lockedSellerId;
        string description;
        string[] images;
        uint256 createdAt;
        RequestLifecycle lifecycle;
        Location location;
        uint256 updatedAt;
    }

    struct Offer {
        uint256 id;
        int256 price;
        string[] images;
        uint256 requestId;
        string storeName;
        uint256 sellerId;
        bool isAccepted;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // Custom errors with Marketplace__ prefix
    error Marketplace__OnlySellersAllowed();
    error Marketplace__UnauthorizedBuyer();
    error Marketplace__OnlyBuyersAllowed();
    error Marketplace__OfferAlreadyAccepted();
    error Marketplace__InvalidAccountType();
    error Marketplace__OfferAlreadyExists();
    error Marketplace__UnauthorizedRemoval();
    error Marketplace__OfferNotRemovable();
    error Marketplace__IndexOutOfBounds();
    error Marketplace__RequestLocked();

    mapping(address => User) public users;
    mapping(uint256 => Request) public requests;
    mapping(uint256 => Offer) public offers;

    uint256 private _userCounter;
    uint256 private _storeCounter;
    uint256 private _requestCounter;
    uint256 private _offerCounter;

    uint256 constant TIME_TO_LOCK = 900;

    function createUser(
        string memory _username,
        string memory _phone,
        int256 _latitude,
        int256 _longitude,
        AccountType _accountType
    ) public {
        if (
            _accountType != AccountType.BUYER &&
            _accountType != AccountType.SELLER
        ) {
            revert Marketplace__InvalidAccountType();
        }

        Location memory userLocation = Location(_latitude, _longitude);

        _userCounter++;
        uint256 userId = _userCounter;

        users[msg.sender] = User(
            userId,
            _username,
            _phone,
            userLocation,
            block.timestamp,
            _accountType
        );

        emit UserCreated(msg.sender, userId, _username, uint8(_accountType));
    }

    function createStore(
        string memory _name,
        string memory _description,
        int256 _latitude,
        int256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Location memory storeLocation = Location(_latitude, _longitude);

        _storeCounter++;
        uint256 storeId = _storeCounter;

        Store memory newStore = Store(
            storeId,
            _name,
            _description,
            storeLocation
        );
        userStores[msg.sender][storeId] = newStore;
        userStoreIds[msg.sender].push(storeId);
        emit StoreCreated(msg.sender, storeId, _name, _latitude, _longitude);
    }

    function createRequest(
        string memory _name,
        string memory _description,
        string[] memory _images,
        int256 _latitude,
        int256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        Location memory requestLocation = Location(_latitude, _longitude);

        _requestCounter++;
        uint256 requestId = _requestCounter;

        Request memory newRequest = Request(
            requestId,
            _name,
            users[msg.sender].id,
            0,
            new uint256[](0),
            new uint256[](0),
            0,
            _description,
            _images,
            block.timestamp,
            RequestLifecycle.PENDING,
            requestLocation,
            block.timestamp
        );
        requests[requestId] = newRequest;
        emit RequestCreated(
            requestId,
            msg.sender,
            _name,
            _latitude,
            _longitude,
            _images,
            uint8(RequestLifecycle.PENDING),
            _description,
            users[msg.sender].id,
            new uint256[](0),
            0,
            0,
            block.timestamp,
            block.timestamp
        );
    }

    function createOffer(
        int256 _price,
        string[] memory _images,
        uint256 _requestId,
        string memory _storeName
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Request storage request = requests[_requestId];

        if (
            block.timestamp > request.updatedAt + TIME_TO_LOCK &&
            request.lifecycle == RequestLifecycle.ACCEPTED_BY_BUYER
        ) {
            revert Marketplace__RequestLocked();
        }

        _offerCounter++;
        uint256 offerId = _offerCounter;

        Offer memory newOffer = Offer(
            offerId,
            _price,
            _images,
            _requestId,
            _storeName,
            users[msg.sender].id,
            false,
            block.timestamp,
            block.timestamp
        );
        offers[offerId] = newOffer;

        emit OfferCreated(
            offerId,
            msg.sender,
            _storeName,
            _price,
            _requestId,
            _images,
            users[msg.sender].id
        );
    }

    function acceptOffer(uint256 _offerId) public {
        Offer storage offer = offers[_offerId];
        Request storage request = requests[offer.requestId];

        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        if (requests[offer.requestId].buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedBuyer();
        }

        if (offer.isAccepted) {
            revert Marketplace__OfferAlreadyAccepted();
        }

        if (
            block.timestamp > request.updatedAt + TIME_TO_LOCK &&
            request.lifecycle == RequestLifecycle.ACCEPTED_BY_BUYER
        ) {
            revert Marketplace__RequestLocked();
        }

        for (uint i = 0; i < request.offerIds.length; i++) {
            uint256 offerId = request.offerIds[i];
            Offer storage previousOffer = offers[offerId];
            previousOffer.isAccepted = false;
            emit OfferAccepted(previousOffer.id, msg.sender, false);
        }

        offer.isAccepted = true;
        offer.updatedAt = block.timestamp;
        request.sellerIds.push(offer.sellerId);
        request.offerIds.push(offer.id);
        request.lockedSellerId = offer.sellerId;
        request.sellersPriceQuote = offer.price;
        request.lifecycle = RequestLifecycle.ACCEPTED_BY_BUYER;
        request.updatedAt = block.timestamp;

        emit RequestAccepted(
            request.id,
            offer.id,
            offer.sellerId,
            request.updatedAt
        );
        emit OfferAccepted(offer.id, msg.sender, true);
    }

    function removeOffer(uint256 _offerId) public {
        Offer storage offer = offers[_offerId];
        Request storage request = requests[offer.requestId];

        // Check if the sender is the seller who created the offer
        if (offer.sellerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedRemoval();
        }

        if (block.timestamp > offer.updatedAt + TIME_TO_LOCK) {
            revert Marketplace__OfferNotRemovable();
        }

        if (
            block.timestamp > request.updatedAt + TIME_TO_LOCK &&
            request.lifecycle == RequestLifecycle.ACCEPTED_BY_BUYER
        ) {
            revert Marketplace__RequestLocked();
        }
        uint indexToRemove;
        bool found = false;

        for (uint i = 0; i < request.sellerIds.length; i++) {
            if (request.sellerIds[i] == offer.sellerId) {
                indexToRemove = i;
                found = true;
                break;
            }
        }
        if (found) {
            // Shift all elements after the one to remove left by one position
            for (
                uint i = indexToRemove;
                i < request.sellerIds.length - 1;
                i++
            ) {
                request.sellerIds[i] = request.sellerIds[i + 1];
            }
            // Remove the last element (duplicate after shifting)
            request.sellerIds.pop();
        }

        // Delete the offer
        delete offers[_offerId];

        // Emit the event
        emit OfferRemoved(_offerId, msg.sender);
    }

    function userStoreCount(address user) public view returns (uint256) {
        return userStoreIds[user].length;
    }

    function getRequestImagesLength(
        uint256 requestId
    ) public view returns (uint256) {
        return requests[requestId].images.length;
    }

    function getRequestImageByIndex(
        uint256 requestId,
        uint256 index
    ) public view returns (string memory) {
        if (index >= requests[requestId].images.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return requests[requestId].images[index];
    }

    function getRequestSellerIdsLength(
        uint256 requestId
    ) public view returns (uint256) {
        return requests[requestId].sellerIds.length;
    }

    function getRequestSellerIdByIndex(
        uint256 requestId,
        uint256 index
    ) public view returns (uint256) {
        if (index >= requests[requestId].sellerIds.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return requests[requestId].sellerIds[index];
    }

    function getOfferImagesLength(
        uint256 offerId
    ) public view returns (uint256) {
        return offers[offerId].images.length;
    }

    function getOfferImageByIndex(
        uint256 offerId,
        uint256 index
    ) public view returns (string memory) {
        if (index >= offers[offerId].images.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return offers[offerId].images[index];
    }
}
