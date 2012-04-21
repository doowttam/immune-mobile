class Immune
  constructor: (@doc, @win) ->
    @canvas  = @doc.getElementById("game_canvas")
    @context = @canvas.getContext("2d")
    @buttons =
      start: @doc.getElementById("start")
      pause: @doc.getElementById("pause")

    # Entities
    @bullets        = []
    @germs          = []
    @powerups       = []
    @activePowerUps = []

    # Status
    @status =
      sickness: 0
      score   : 0
      freeze: false

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @defender = new Defender( @canvas.width / 2, @canvas.height - 50 )

  resetCanvas: ->
    @canvas.width = @canvas.width

  drawFrame: ->
    @resetCanvas()

    @drawBullets()
    damage = @drawGerms(@bullets, @activePowerUps)
    @drawPowerUps(@bullets)
    @drawActivePowerUps(@bullets)

    @defender.move(@canvas, @key, @bullets)
    @defender.draw(@context)

    if !@status.freeze
      @spawnGerms()
      @spawnPowerUps()

    @drawStatus()

    if @status.sickness > 99
      @gameOver()
    else if damage
      @context.fillStyle = 'red'
      @context.fillRect 0, 0, @canvas.width, @canvas.height

  gameOver: ->
    @pause()
    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "You got sick!", @canvas.width / 2, 125

    @context.fillStyle = 'white'
    @context.font = 'bold 36px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Score: " + @status.score, @canvas.width / 2, 200

  drawStatus: ->
    @context.fillStyle = 'rgba(0,0,0,.5)'
    @context.fillRect 0, 25, 75, 24

    @context.fillStyle = 'white'
    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'left'
    @context.fillText "Score: " + @status.score, 5, 42

    @context.fillStyle = 'rgba(0,0,0,.5)'
    @context.fillRect @canvas.width, 25, -100, 24

    @context.fillStyle = 'white'
    @context.font = 'bold 12px sans-serif'
    @context.textAlign = 'right'
    @context.fillText 'Sickness: ' + @status.sickness + '%', @canvas.width - 5, 42

  spawnGerms: ->
    if Math.random() < 0.01
      randX = Math.ceil Math.random() * @canvas.width
      @germs.push( new Germ randX, 0 );

  spawnPowerUps: ->
    if Math.random() < 0.005
      randX = Math.ceil Math.random() * @canvas.width
      @powerups.push( new PowerUp randX, 0 );

  drawGerms: (bullets, powerups) ->
    toCleanUp = [];
    damage    = false

    if @germs.length > 0
      for germIndex in [ 0 .. @germs.length - 1 ]
        germ = @germs[germIndex]
        germ.move(@context) if !@status.freeze
        germ.draw(@context)

        bulletHit  = germ.isHit(bullets)
        powerUpHit = germ.isHit(powerups)
        if bulletHit.hit
          toCleanUp.push germIndex
          if bulletHit.absorb
            @status.sickness = @status.sickness + germ.damage
            damage = true
          else
            @status.score++
        else if powerUpHit.hit
          toCleanUp.push germIndex
          powerUpHit.item.takeDamage()
        else if germ.isOffscreen(@canvas)
          @status.sickness = @status.sickness + germ.damage
          damage = true
          toCleanUp.push germIndex

      for germIndex in toCleanUp
        @germs.splice germIndex, 1

    return damage

  drawPowerUps: (bullets) ->
    toCleanUp = [];

    if @powerups.length > 0
      for powerupIndex in [ 0 .. @powerups.length - 1 ]
        powerup = @powerups[powerupIndex]
        powerup.move(@context)
        powerup.draw(@context)

        powerupHit = powerup.isHit(bullets)
        if powerupHit.hit
          toCleanUp.push powerupIndex
          if powerupHit.absorb
            powerup.activate(@canvas, @status)
            @activePowerUps.push powerup
        else if powerup.isOffscreen(@canvas)
          toCleanUp.push powerupIndex

      for powerupIndex in toCleanUp
        @powerups.splice powerupIndex, 1

  drawActivePowerUps: (germs) ->
    toCleanUp = [];

    if @activePowerUps.length > 0
      for powerUpIndex in [ 0 .. @activePowerUps.length - 1 ]
        powerup = @activePowerUps[powerUpIndex]
        powerup.draw @context
        if powerup.health < 1
          toCleanUp.push powerUpIndex

      for powerUpIndex in toCleanUp
        @activePowerUps.splice powerUpIndex, 1

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

class Germ
  constructor: (@x, @y) ->
    @speed = 1
    @width = 10
    @height = 10
    @damage = 20

  draw: (context)->
    context.fillStyle = 'green'
    context.fillRect @x, @y, @width, @height

  move: ->
    @y = @y + @speed;

  isOffscreen: (canvas) -> if @y > canvas.height then true else false

  isHit: (items) ->
    for item in items
      if ( @x <= item.x + item.width and
           @x + @width >= item.x and
           @y <= item.y + item.height and
           @y + @height >= item.y )
        return { hit: true, absorb: item.absorb, item: item }
    return { hit: false }

class PowerUp extends Germ
  constructor: (@x, @y) ->
    super @x, @y

    if Math.random() < 0.5
      @type = 'freeze'
    else
      @type = 'shield'

  activate: (canvas, status) ->
    if @type == 'freeze'
      status.freeze = true
      setTimeout =>
        status.freeze = false
        @health = 0
      , 3000
    else
      @width = canvas.width
      @x = 0
      @health = 3

  takeDamage: ->
    @health--
    @height = @height - 2

  draw: (context) ->
    if @type == 'shield'
      context.fillStyle = 'blue'
    else
      context.fillStyle = 'purple'
    context.fillRect @x, @y, @width, @height

class Defender
  constructor: (@x, @y) ->
    @speed  = 2
    @width  = 24
    @height = 10

  draw: (context)->
    context.fillStyle = 'black'
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
    if key.isDown(key.codes.DOWN)
      @absorb(bullets)

  fire: (bullets) ->
    bullets.push(new Bullet @x + @width / 2, @y)

  absorb: (bullets) ->
    bullets.push(new AbsorbBullet @x + @width / 2, @y)

class Bullet
  constructor: (@x, @y) ->
    @speed = 3
    @width = 4
    @height = 4

  draw: (context)->
    context.fillStyle = 'black'
    context.fillRect @x - @width / 2, @y, @width, @height

  move: ->
    @y = @y - @speed;

  isOffscreen: -> if @y < 0 then true else false

class AbsorbBullet extends Bullet
  absorb: true

  draw: (context)->
    context.fillStyle = 'orange'
    context.fillRect @x - @width / 2, @y, @width, @height

window.onload = ->
  immune = new Immune window.document, window
  immune.drawFrame()
  immune.play()
