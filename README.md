# pd-vow

Various classes designed to help with making network requests on Playdate.

## wot?

Yep! This library contains a few classes which make network stuff a bit easier to handle on Playdate (at least in my opinion haha):

- `Vow`
- `VowChain`

## `Vow`

`Vow` is essentially a wrapper class for `playdate.network.http.new`. Here's a simple request example:

```lua
local vow = Vow("example.com") -- request home page of `example.com` as soon as possible!
vow:setRequestCompleteCallback(function(data)
    print(data)
end)
```

That's all there is to it! There are some more arguments you can pass in to `Vow` (to `POST` data, for example) but that's a basic request.

## `VowChain`

`VowChain` chains multiple `Vow`s together, one after another! In a `VowChain`, each `Vow` in the chain is called in order. Once the current `Vow` finishes its request, it calls the function at the current `Vow` index in the functions table, and if that returns `true` then it continues the chain, otherwise it doesn't.

```lua
local chain = { -- Vows waiting to be spoken...
    Vow("example.com", true), -- setting `latent` variable to `true` to disable automatic Vow execution, the VowChain does this itself
    Vow("wikipedia.org", true),
    Vow("devforum.play.date", true)
}

local functions = {
    function(data)
        print("one!")
        print(data)

        return true -- continue chain...
    end,
    function(data)
        print("two!")
        print(data)

        return false -- stop chain here!
    end,
    function(data)
        print("woah, this won't be called!")
    end
}

VowChain(chain, functions) -- starts chain immediately
```
