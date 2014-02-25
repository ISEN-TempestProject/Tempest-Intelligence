function getById(arr, id) {
    for (var i = 0, len = arr.length; i < len; i += 1) {
        if (arr[i].id === id) {
            return arr[i];
        }
    }
}