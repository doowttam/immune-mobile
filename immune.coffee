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

    @resource = {}

    # Status
    @status =
      sickness: 0
      score   : 0
      freeze: false
      activeFreezePowerUp: null

    @buttons.start.onclick = @play
    @buttons.pause.onclick = @pause

    @key = new Key
    @win.onkeyup = (e) =>
      @key.onKeyUp e
    @win.onkeydown = (e) =>
      @key.onKeyDown e

    @defender = new Defender( @canvas.width / 2, @canvas.height - 50 )

    @loadResources =>
        @buttons.start.disabled = false
        @showTitleScreen()

  loadResources: ( playCallback ) ->
    imageCount = 0
    audioCount = 0

    images = [ 'img/germ.png' ];
    audios = [ 'sfx/shoot.ogg', 'sfx/explode.ogg', 'sfx/damage.ogg', 'sfx/absorb.ogg', 'sfx/powerup.ogg' ];

    finished = false;

    @loading( imageCount + audioCount, images.length + audios.length );

    # Just in case things take too long
    setTimeout ->
      if !finished
        playCallback();
        finished = true
    , 4000

    resourceOnLoad = (type) =>
      if type == 'image'
        imageCount++
      if type == 'audio'
        audioCount++

      @loading( imageCount + audioCount, images.length + audios.length );

      if imageCount == images.length and audioCount == audios.length
        if !finished
          playCallback()
        finished = true

    for imageName in images
      img = new Image()
      img.src = imageName
      img.addEventListener 'load', -> resourceOnLoad('image')
      @resource[imageName] = img

    for audioName in audios
      sound = new Audio()
      sound.src = audioName
      sound.addEventListener 'canplaythrough', -> resourceOnLoad('audio')
      @resource[audioName] = sound

  resetCanvas: ->
    @canvas.width = @canvas.width

  loading: (cur, total) ->
    @resetCanvas();

    msg = "Loading (#{cur}/#{total})..."

    @context.font = "bold 12px sans-serif"

    @context.textAlign = "center"
    @context.textBaseline = "middle"
    @context.fillText msg, @canvas.width - @canvas.width / 2, @canvas.height - @canvas.height / 2

  showTitleScreen: ->
    @resetCanvas();
    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'black'
    @context.font = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Immune", @canvas.width / 2, 125

  showPauseScreen: ->
    @context.fillStyle = 'rgba(0,0,0,.7)'
    @context.fillRect 0, 0, @canvas.width, @canvas.height

    @context.fillStyle = 'white'
    @context.font = 'bold 48px sans-serif'
    @context.textAlign = 'center'
    @context.fillText "Paused", @canvas.width / 2, 125

  drawFrame: ->
    @resetCanvas()

    damage = @drawGerms(@bullets, @activePowerUps, @resource)
    @drawPowerUps(@bullets, @resource)
    @drawActivePowerUps(@bullets)

    @drawBullets()
    @defender.move(@canvas, @key, @bullets, @resource)
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
      @resource['sfx/damage.ogg'].play()

  gameOver: ->
    @over = true
    clearInterval @frameInterval
    @frameInterval = null

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
      if Math.random() < 0.7
        @germs.push( new Germ randX, 0 );
      else
        @germs.push( new GiantGerm randX, 0 );

  spawnPowerUps: ->
    if Math.random() < 0.005
      randX = Math.ceil Math.random() * @canvas.width
      @powerups.push( new PowerUp randX, 0 );

  drawGerms: (bullets, powerups, resource) ->
    toCleanUp = [];
    damage    = false

    if @germs.length > 0
      for germIndex in [ 0 .. @germs.length - 1 ]
        germ = @germs[germIndex]
        germ.move(@context) if !@status.freeze
        germ.draw(@context, resource)

        bulletHit  = germ.isHit(bullets)
        powerUpHit = germ.isHit(powerups)
        if bulletHit.hit
          if bulletHit.absorb
            germ.health = 0
            @status.sickness = @status.sickness + germ.damage
            damage = true
          else
            germ.health--
            @status.score++
            if germ.health < 1
              resource['sfx/explode.ogg'].play()
          toCleanUp.push germIndex if germ.health < 1
        else if powerUpHit.hit
          toCleanUp.push germIndex
          powerUpHit.item.takeDamage(germ.damage)
          resource['sfx/explode.ogg'].play()
        else if germ.isOffscreen(@canvas)
          @status.sickness = @status.sickness + germ.damage
          damage = true
          toCleanUp.push germIndex

      for germIndex in toCleanUp
        @germs.splice germIndex, 1

    return damage

  drawPowerUps: (bullets, resource) ->
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
            powerup.activate(@canvas, @status, resource)
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
        if bullet.usedUp()
          toCleanUp.push bulletIndex

      for bulletIndex in toCleanUp
        @bullets.splice bulletIndex, 1

  play: =>
    return if @frameInterval

    if @over
      location.reload()
    else
      @frameInterval =
        setInterval =>
          @drawFrame()
        , 20

  pause: =>
    if @frameInterval
      clearInterval @frameInterval
      @frameInterval = null
      @showPauseScreen()
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
    @speed  = 1
    @width  = 10
    @height = 10
    @damage = 20
    @health = @baseHealth = 1
    @frame  = 0

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/germ.png'], 20 * offset, 0, 20 , 20, @x, @y, @width, @height

  move: ->
    @y = @y + @speed;
    if @frame < 9 then @frame++ else @frame = 0;

  isOffscreen: (canvas) -> if @y > canvas.height then true else false

  isHit: (items) ->
    for item in items
      if ( @x <= item.x + item.width and
           @x + @width >= item.x and
           @y <= item.y + item.height and
           @y + @height >= item.y )
        item.hitSomething = true
        return { hit: true, absorb: item.absorb, item: item }
    return { hit: false }

class GiantGerm extends Germ
  constructor: (@x, @y) ->
    @speed = 0.5
    @width = 20
    @height = 20
    @damage = 60
    @health = @baseHealth = 15

  draw: (context, resource)->
    offset = if @frame <= 4 then 1 else 0
    context.drawImage resource['img/germ.png'], 20 * offset, 0, 20 , 20, @x, @y, @width, @height
    context.fillStyle = 'red'
    if @health < @baseHealth
      healthWidth = @width * @health / @baseHealth
      context.fillRect @x, @y, healthWidth, 5


class PowerUp extends Germ
  constructor: (@x, @y) ->
    @speed = 1
    @width = 10
    @height = 10
    @damage = 20

    if Math.random() < 0.5
      @type = 'freeze'
    else
      @type = 'shield'

  freezeTimeout: null

  cancelFreeze: ->
    clearTimeout @freezeTimeout
    @health = 0

  activate: (canvas, status, resource) ->
    resource['sfx/powerup.ogg'].play()
    if @type == 'freeze'
      status.freeze = true

      if status.activeFreezePowerUp
        status.activeFreezePowerUp.cancelFreeze()

      status.activeFreezePowerUp = @
      @freezeTimeout =
        setTimeout =>
          status.freeze = false
          status.activeFreezePowerUp = null
          @health = 0
        , 3000
    else
      @width = canvas.width
      @x = 0
      @health = 60

  takeDamage: (damage) ->
    @health = @health - damage
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
    @cooldown = false

  draw: (context)->
    context.fillStyle = 'black'
    context.fillRect @x, @y, @width, @height
    context.fillStyle = 'red'
    context.fillRect @x + @width / 4, @y - @height / 2, @width / 2, @height / 2

  move: (canvas, key, bullets, resource) ->
    if key.isDown(key.codes.LEFT) and @x - @speed >= 0
      @x = @x - @speed
    if key.isDown(key.codes.RIGHT) and @x + @speed <= canvas.width - @width
      @x = @x + @speed
    if key.isDown(key.codes.UP)
      @fire(bullets, resource)
    if key.isDown(key.codes.DOWN)
      @absorb(bullets, resource)

  fire: (bullets, resource) ->
    return if @cooldown
    resource['sfx/shoot.ogg'].play()
    bullets.push(new Bullet @x + @width / 2, @y)
    @cooldown = true
    setTimeout =>
      @cooldown = false
    , 100

  absorb: (bullets, resource) ->
    return if @cooldown
    resource['sfx/absorb.ogg'].play()
    bullets.push(new AbsorbBullet @x + @width / 2, @y)
    @cooldown = true
    setTimeout =>
      @cooldown = false
    , 100

class Bullet
  constructor: (@x, @y) ->
    @speed = 3
    @width = 4
    @height = 10
    @hitSomething = false

  draw: (context)->
    context.fillStyle = 'black'
    context.fillRect @x - @width / 2, @y, @width, @height

  move: ->
    @y = @y - @speed;

  usedUp: ->
    if @isOffscreen() or @hitSomething then true else false

  isOffscreen: -> if @y < 0 then true else false

class AbsorbBullet extends Bullet
  absorb: true

  draw: (context)->
    context.fillStyle = 'orange'
    context.fillRect @x - @width / 2, @y, @width, @height

window.onload = ->
  immune = new Immune window.document, window
