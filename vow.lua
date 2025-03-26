-- "i, [      ] will be right beside you, through rain and shine, through thick and thin, forever and ever."

-- Vow and VowChain by nanobot567!
-- do whatever you want, idrc, but credit would be cool :3

import "CoreLibs/object"

local pd <const> = playdate

---@class Vow
---@field REQUEST_TYPE_GET number 0
---@field REQUEST_TYPE_POST number 1
---@field server playdate.network.http network object used for requests
---@field path string path from server root
---@field sendData string data that will be sent to the server
---@field sendHeaders string headers that will be sent to the server
---@field data string data downloaded from server
---@field headers string headers downloaded from server
---@field private _headersReadCallback function
---@field private _requestCallback function
---@field private _requestCompleteCallback function
Vow = {}
class("Vow").extends()

Vow.REQUEST_TYPE_GET = 0
Vow.REQUEST_TYPE_POST = 1

---Creates a new Vow, and unless `latent` is `true`, sends the specified request to the server.
---
---If `latent` is `false` or not specified, will return `true` if the request was successfully made, or `false` and the error message if it wasn't.
---
---@param server playdate.network.http|string server to request data from
---@param latent? boolean if `true`, the Vow will not call :speak() immediately on creation, defaults to `false`
---@param path? string path on server to get data from, defaults to `/`
---@param requestType? integer either `Vow.REQUEST_TYPE_GET` (0) or `Vow.REQUEST_TYPE_POST` (1), defaults to `Vow.REQUEST_TYPE_GET`
---@param headers? any headers to include in request
---@param data? any data to send to server if requestType is `Vow.REQUEST_TYPE_POST`
---@return nil|boolean|boolean, string
function Vow:init(server, latent, path, requestType, headers, data)
  assert(type(server) == "userdata" or type(server) == "string", "server must be string or playdate.network.http object")

  if type(server) == "string" then
    server = pd.network.http.new(server)
  end
  
  self.server = server

  path = path or "/"
  data = data or ""
  requestType = requestType or Vow.REQUEST_TYPE_GET
  headers = headers or {}
  latent = latent or false

  self.path = path

  self.sendData = data
  self.sendHeaders = headers
  
  self.data = ""
  self.headers = ""

  self.responseCompleted = false
  self.receivedResponse = false
  self.error = nil
  self.requestCompleteCallback = nil

  self.type = requestType

  server:setRequestCallback(function()
    self:_requestCallback()
  end)

  server:setRequestCompleteCallback(function ()
    self:_requestCompleteCallback()

    if self.requestCompleteCallback then
      self.requestCompleteCallback(self.data)
    end
  end)

  server:setHeadersReadCallback(function ()
    self:_headersReadCallback()
  end)

  if not latent then
    return self:speak()
  end
end

function Vow:_headersReadCallback()
  self.headers = self.server:getResponseHeaders()
  self.receivedResponse = true
end

function Vow:_requestCallback()
  self.data = self.data .. self.server:read()
end

function Vow:_requestCompleteCallback()
  self.responseCompleted = true
end


---Checks if the request has been completed. If so, returns the downloaded data, otherwise returns `nil`.
---
---@return nil|string
function Vow:listen()
  if self.responseCompleted then
    return self.data
  end
  return nil or self.error
end


---Returns the current download progress as an integer from 0-100, or `nil` if a response hasn't been recieved from the server yet.
---
---@return nil|integer
function Vow:progress()
  if self.headers then
    local read, planned = self.server:getProgress()

    if read == 0 and planned == 0 then
      return 0
    end

    return math.min((read / planned) * 100, 100)
  end
  return nil
end

---Make a request to the server. Returns if the network request was successfully made or not, and if not, a string detailing the error will be returned as well.
---
---@return nil|boolean|boolean, string
function Vow:speak()
  self.data = ""
  self.headers = ""

  if self.type == Vow.REQUEST_TYPE_GET then
    return self.server:get(self.path, self.sendHeaders)
  elseif self.type == Vow.REQUEST_TYPE_POST then
    return self.server:post(self.path, self.sendHeaders, self.sendData)
  end
end

---Set the function to be executed as soon as the network request is completed.
---
---@param fn function
function Vow:setRequestCompleteCallback(fn)
  self.requestCompleteCallback = fn
end

---@class VowChain
VowChain = {}
class("VowChain").extends()

---Create chained network requests.
---
---`vows` should be a table containing `Vow` objects (preferrably with `latent` set to `true`).
---
---On initialization (or whenever you call `:speak()`), a `VowChain` will iterate through each `Vow` in `vows` and call `:speak()`. Once the `Vow`'s request is complete, the function in the `funcs` table at the current `Vow`'s index will be executed. If the function returns `true`, the `VowChain` will proceed to the next `Vow`, otherwise it will halt the chain.
--
---Functions in `funcs` will be passed both the data recieved from the server, as well as the next `Vow` in the chain if there is one.
---
---This overwrites previously defined `requestCompleteCallback`s in each `Vow`.
---
---@param vows table
---@param funcs table
---@param latent? boolean
function VowChain:init(vows, funcs, latent) -- TODO: error handling!
  self.vows = vows

  assert(#vows == #funcs, "function table length is not equal to vow table length")

  for i, v in ipairs(vows) do
    v:setRequestCompleteCallback(function(data)
      local vow = nil

      if i < #vows then
        vow = vows[i + 1]
      end

      if funcs[i](data, vow) then -- does function return true?
        if vow then
          vow:speak()
        end
      end
    end)
  end

  if not latent then
    return vows[1]:speak()
  end
end

function VowChain:speak()
  return self.vows[1]:speak()
end
