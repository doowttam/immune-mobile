class Immune
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")
    @bullets = [];

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @defender = new Defender( @canvas.width / 2, @canvas.height - 50 );

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: ->
    @resetCanvas()

    @drawBullets()
    @defender.move(@canvas, @key, @bullets);
    @defender.draw(@context);

  drawBullets: ->
    toCleanUp = [];

    if @bullets.length > 0
      for bulletIndex in [ 0 .. @bullets.length - 1 ]
        bullet = @bullets[bulletIndex]
        bullet.move(@context)
        bullet.draw(@context)
        if bullet.isOffscreen()
          toCleanUp.push bulletIndex

      for bulletIndex in toCleanUp
        @bullets.splice bulletIndex, 1

  play: =>
    return if @frameInterval
    @frameInterval =
      setInterval =>
        @drawFrame()
      , 20

  pause: =>
    if @frameInterval
      clearInterval @frameInterval
      @frameInterval = null
    else
      @play()

# Inspired by http://nokarma.org/2011/02/27/javascript-game-development-keyboard-input/index.html
class Key
  pressed: {}

  codes:
    "LEFT": 37
    "UP": 38
    "RIGHT": 39
    "DOWN": 40
    "SPACE": 32

  isDown: (keyCode) =>
    return @pressed[keyCode]

  onKeyDown: (event) =>
    @pressed[event.keyCode] = true

  onKeyUp: (event) =>
    delete @pressed[event.keyCode]

class Defender
  constructor: (@x, @y) ->
    @speed  = 2
    @width  = 24
    @height = 10

  draw: (context)->
    context.fillRect @x, @y, @width, @height
    context.fillStyle = 'red'
    context.fillRect @x + @width / 4, @y - @height / 2, @width / 2, @height / 2

  move: (canvas, key, bullets) ->
    if key.isDown(key.codes.LEFT) and @x - @speed >= 0
      @x = @x - @speed
    if key.isDown(key.codes.RIGHT) and @x + @speed <= canvas.width - @width
      @x = @x + @speed
    if key.isDown(key.codes.UP)
      @fire(bullets)

  fire: (bullets) ->
    bullets.push(new Bullet @x + @width / 2, @y)

class Bullet
  constructor: (@x, @y) ->
    @speed = 3
    @width = 4
    @height = 5

  draw: (context)->
    context.fillRect @x - @width / 2, @y, @width, @height

  move: ->
    @y = @y - @speed;

  isOffscreen: -> if @y < 0 then true else false

window.onload = ->
  immune = new Immune window.document, window
  immune.drawFrame()
  immune.play()
