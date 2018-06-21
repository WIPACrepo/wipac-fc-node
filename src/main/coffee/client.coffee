# client.coffee
#-----------------------------------------------------------------------

# import requests
# import json
# import os
{Client} = require "node-rest-client"
urljoin = require "url-join"

# class ClientError(Exception):
#     """
#     Errors that occur at client side.
#     """
#
#     pass
class exports.ClientError extends Error
  constructor: (message) ->
    super message

# class Error(Exception):
#     """
#     Errors that occur at server side.
#     """
#
#     def __init__(self, message, code, *args):
#         self.message = message
#         self.code = code
#
#         # Try to decode message if it is a json string:
#         try:
#             self.message = json.loads(self.message)['message']
#         except:
#             # If it fails, just let the message as is
#             pass
#
#         super(Error, self).__init__(self.message, code, *args)

# class BadRequestError(Error):
#     def __init__(self, message, *args):
#         super(BadRequestError, self).__init__(message, 400, *args)
class exports.BadRequestError extends Error
  constructor: (message) ->
    super message
    @code = 400

# class TooManyRequestsError(Error):
#     def __init__(self, message, *args):
#         super(TooManyRequestsError, self).__init__(message, 429, *args)
class exports.TooManyRequestsError extends Error
  constructor: (message) ->
    super message
    @code = 429

# class UnspecificServerError(Error):
#     def __init__(self, message, *args):
#         super(UnspecificServerError, self).__init__(message, 500, *args)
class exports.UnspecificServerError extends Error
  constructor: (message) ->
    super message
    @code = 500

# class ServiceUnavailableError(Error):
#     def __init__(self, message, *args):
#         super(ServiceUnavailableError, self).__init__(message, 503, *args)
class exports.ServiceUnavailableError extends Error
  constructor: (message) ->
    super message
    @code = 503

# class ConflictError(Error):
#     def __init__(self, message, *args):
#         super(ConflictError, self).__init__(message, 409, *args)
class exports.ConflictError extends Error
  constructor: (message) ->
    super message
    @code = 409

# class NotFoundError(Error):
#     def __init__(self, message, *args):
#         super(NotFoundError, self).__init__(message, 404, *args)
class exports.NotFoundError extends Error
  constructor: (message) ->
    super message
    @code = 404

# def error_factory(code, message):
#     """
#     Tries to find the correct `Error` class. If no class is found that corresponds to the `code`,
#     it will utilize the `Error` class it self.
#     """
#     if 'cls' not in error_factory.__dict__ or 'codes' not in error_factory.__dict__:
#         error_factory.__dict__['cls'] = Error.__subclasses__()
#         error_factory.__dict__['codes'] = [c('').code for c in error_factory.__dict__['cls']]
#
#     try:
#         # `index()` throws an `ValueError` if the value isn't found
#         i = error_factory.__dict__['codes'].index(code)
#         return error_factory.__dict__['cls'][i](message)
#     except ValueError:
#         return Error(message, code)
ERROR_BY_CODE =
  400: exports.BadRequestError
  404: exports.NotFoundError
  409: exports.ConflictError
  429: exports.TooManyRequestsError
  500: exports.UnspecificServerError
  503: exports.ServiceUnavailableError

exports.error_factory = error_factory = (code, message) ->
  if ERROR_BY_CODE[code]?
    return new (ERROR_BY_CODE[code]) message
  err = new Error message
  err.code = code
  return err

# class WFCClient:
#     def __init__(self, url, port=None, use_session=False):
#         """
#         Initializes the client.
#
#         If a port is specified, it is added to the `url`, e.g. `https://example.com:8080`.
#         """
#         self._url = url
#
#         if port is not None:
#             self._url = self._url + ':' + str(port)
#
#         # add base api path:
#         self._url = os.path.join(self._url, 'api')
#
#         # use session?
#         if use_session:
#             self._r = requests.Session()
#         else:
#             self._r = requests
class exports.WFCClient
  #---------------------------------------------------------------------
  # WIPAC File Catalog Client
  #---------------------------------------------------------------------

  constructor: (@url, port = undefined, use_session = false) ->
    throw new Error "(use_session = true) Not Supported" if use_session
    @url = "#{@url}:#{port}" if port?
    @url = urljoin @url, "api"
    @client = new Client()

  #---------------------------------------------------------------------
  # Files
  #---------------------------------------------------------------------

  # def get_files(self, run_number=None, dataset=None, event_id=None,
  #               processing_level=None, season=None, keys=None):
  #     """
  #     Queries files from the file catalog.
  #     """
  #     payload = {}
  #
  #     if run_number is not None:
  #         payload['run_number'] = int(run_number)
  #
  #     if dataset is not None:
  #         payload['dataset'] = int(dataset)
  #
  #     if event_id is not None:
  #         payload['event_id'] = int(event_id)
  #
  #     if processing_level is not None:
  #         payload['processing_level'] = processing_level
  #
  #     if season is not None:
  #         payload['season'] = int(season)
  #
  #     if keys is not None:
  #         payload['keys'] = '|'.join(keys)
  #
  #     r = self._r.get(os.path.join(self._url, 'files'), params=payload)
  #
  #     if r.status_code == requests.codes.OK:
  #         rdict = r.json()
  #
  #         return rdict['files']
  #     else:
  #         raise error_factory(r.status_code, r.text)
  get_files: (options = {}) ->
    # var args = {
    #     data: { test: "hello" }, // data passed to REST method (only useful in POST, PUT or PATCH methods)
    #     path: { "id": 120 }, // path substitution var
    #     parameters: { arg1: "hello", arg2: "world" }, // this is serialized as URL parameters
    #     headers: { "test-header": "client-api" } // request headers
    # };
    {run_number, dataset, event_id, processing_level, season, keys} = options

    args =
      parameters: {}
    args.parameters.run_number = parseInt run_number if run_number?
    args.parameters.dataset = parseInt dataset if dataset?
    args.parameters.event_id = parseInt event_id if event_id?
    args.parameters.processing_level = processing_level if processing_level?
    args.parameters.season = parseInt season if season?
    args.parameters.keys = keys.join "|" if keys?

    filesUrl = urljoin @url, "files"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, args, (data, response) ->
        return resolve data.files
      .on "error", (err) ->
        return reject err

  # def get_list(self, query={}, start=None, limit=None):
  #     """
  #     Queries the file list from the file catalog.
  #
  #     This method caches the uid/mongo_id mapping in order to be able
  #     querying files by uid faster.
  #     """
  #     payload = {}
  #
  #     if start is not None:
  #         payload['start'] = int(start)
  #
  #     if limit is not None:
  #         payload['limit'] = int(limit)
  #
  #     if not isinstance(query, dict):
  #         raise ClientError('Argument `query` must be a dict.')
  #
  #     if query:
  #         payload['query'] = json.dumps(query)
  #
  #     r = self._r.get(os.path.join(self._url, 'files'), params=payload)
  #
  #     if r.status_code == requests.codes.OK:
  #         rdict = r.json()
  #
  #         return rdict
  #     else:
  #         raise error_factory(r.status_code, r.text)
  get_list: (options = {}) ->
    {query, start, limit} = options

    args =
      parameters: {}
    args.parameters.start = parseInt start if start?
    args.parameters.limit = parseInt limit if limit?
    args.parameters.query = JSON.stringify query if query?

    filesUrl = urljoin @url, "files"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, args, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  # def get(self, uid):
  #     """
  #     Queries meta information for a specific file uid.
  #     """
  #     r = self._r.get(os.path.join(self._url, 'files', uid))
  #
  #     if r.status_code == requests.codes.OK:
  #         return r.json()
  #     else:
  #         raise error_factory(r.status_code, r.text)
  get: (uid) ->
    filesUrl = urljoin @url, "files", uid

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  # def get_etag(self, uid):
  #     """
  #     Queries meta information for a specific file uid.
  #     """
  #     r = self._r.get(os.path.join(self._url, 'files', uid))
  #
  #     if r.status_code == requests.codes.OK and 'etag' in r.headers:
  #         return r.headers['etag']
  #     else:
  #         raise Error('The server responded without an etag', -1)
  get_etag: (uid) ->
    filesUrl = urljoin @url, "files", uid

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        if response.headers?.etag?
          return resolve response.headers.etag
        return reject new Error "The server responded without an etag"
      .on "error", (err) ->
        return reject err

  # def create(self, metadata):
  #     """
  #     Tries to create a file in the file catalog.
  #
  #     `metadata` must be a dictionary and needs to contain at least all mandatory fields.
  #
  #     *Note*: The client does not check the metadata. Checks are entirely done by the server.
  #     """
  #     r = self._r.post(os.path.join(self._url, 'files'), json.dumps(metadata))
  #
  #     if r.status_code == requests.codes.CREATED:
  #         # Add uid/mongo_id to cache
  #         rdict = r.json()
  #         return rdict
  #     elif r.status_code == requests.codes.OK:
  #         # Replica added
  #         return r.json()
  #     else:
  #         raise error_factory(r.status_code, r.text)
  create: (metadata) ->
    filesUrl = urljoin @url, "files"

    args =
      data: metadata
      headers:
        "Content-Type": "application/json"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.post filesUrl, args, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  # def update(self, uid, metadata={}):
  #     """
  #     Updates/patches a metadata of a file.
  #     """
  #     return self._update_or_replace(uid=uid, metadata=metadata, method=self._r.patch)
  update: (uid, metadata) ->
    return @_update_or_replace uid, metadata, @client.patch

  # def _update_or_replace(self, uid, metadata={}, method=None):
  #     """
  #     Since `patch` and `put` have the same interface but do different things,
  #     we only need one method with a switch.
  #     """
  #
  #     if not metadata:
  #         raise ClientError('No metadata has been passed to update file metadata')
  #
  #     # TODO: Remove support for etag as they are not being used properly in the
  #     # patch method.
  #     etag = self.get_etag(uid)
  #     r = method(os.path.join(self._url, 'files', uid),
  #                data=json.dumps(metadata),
  #                headers={'If-None-Match': etag})
  #
  #     if r.status_code == requests.codes.OK:
  #         return r.json()
  #     else:
  #         raise error_factory(r.status_code, r.text)
  _update_or_replace: (uid, metadata, method) ->
    {ClientError} = exports
    if not uid?
      return Promise.reject new ClientError "No UID was provided to be updated or replaced"
    if not metadata?
      return Promise.reject new ClientError "No metadata has been passed to update file metadata"
    if not method?
      return Promise.reject new ClientError "No method has been provided to update or replace"

    filesUrl = urljoin @url, "files", uid
    data = JSON.stringify metadata
    etag = await @get_etag uid

    # var args = {
    #     data: { test: "hello" }, // data passed to REST method (only useful in POST, PUT or PATCH methods)
    #     path: { "id": 120 }, // path substitution var
    #     parameters: { arg1: "hello", arg2: "world" }, // this is serialized as URL parameters
    #     headers: { "test-header": "client-api" } // request headers
    # };
    args =
      data: data
      headers:
        "Content-Type": "application/json"
        "If-None-Match": etag

    return new Promise (resolve, reject) ->
      method filesUrl, args, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  # def replace(self, uid, metadata={}):
  #     """
  #     Replaces the metadata of a file except for `mongo_id` and `uid`.
  #     """
  #     return self._update_or_replace(uid=uid, metadata=metadata, method=self._r.put)
  replace: (uid, metadata) ->
    return @_update_or_replace uid, metadata, @client.put

  # def delete(self, uid):
  #     """
  #     Deletes the metadata of a file.
  #     """
  #     r = requests.delete(os.path.join(self._url, 'files', uid))
  #
  #     if r.status_code != requests.codes.NO_CONTENT:
  #         raise error_factory(r.status_code, r.text)
  delete: (uid) ->
    return Promise.reject new Error "delete Not Supported"

  #---------------------------------------------------------------------
  # Collections
  #---------------------------------------------------------------------

  create_collection: (metadata) ->
    filesUrl = urljoin @url, "collections"

    args =
      data: metadata
      headers:
        "Content-Type": "application/json"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.post filesUrl, args, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  get_collection: (uid) ->
    filesUrl = urljoin @url, "collections", uid

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  get_collections: (options = {}) ->
    filesUrl = urljoin @url, "collections"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  #---------------------------------------------------------------------
  # Snapshots
  #---------------------------------------------------------------------

  create_snapshot: (collection, metadata) ->
    filesUrl = urljoin @url, "collections", collection.uuid, "snapshots"

    args =
      data: metadata
      headers:
        "Content-Type": "application/json"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.post filesUrl, args, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  get_snapshot: (uid) ->
    filesUrl = urljoin @url, "snapshots", uid

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

  get_snapshot_files: (uid) ->
    filesUrl = urljoin @url, "snapshots", uid, "files"

    restClient = @client
    return new Promise (resolve, reject) ->
      restClient.get filesUrl, (data, response) ->
        try
          obj = JSON.parse data
        catch err
          return reject err
        return resolve obj
      .on "error", (err) ->
        return reject err

#-----------------------------------------------------------------------
# end of client.coffee
