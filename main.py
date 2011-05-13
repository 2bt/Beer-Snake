#!/usr/bin/python
import math
import random

import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GLU import *
import font

def center(x, y, text): font.put(x - len(text) * 8 + 8, y, text)


class Sprite:

	SCALE_FACTOR = 5

	def __init__(self, img_name):

		img = pygame.image.load(img_name)
		w, h = img.get_size()
		ws = w * self.SCALE_FACTOR
		hs = h * self.SCALE_FACTOR
		img = pygame.transform.scale(img, (ws, hs))
		data = pygame.image.tostring(img, "RGBA", True)

		self.tex = glGenTextures(1)

		glBindTexture(GL_TEXTURE_2D, self.tex)
		gluBuild2DMipmaps(GL_TEXTURE_2D, 4, ws, hs, GL_RGBA, GL_UNSIGNED_BYTE, data)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)

		self.size = h
		self.frames = w / h
		self.list = glGenLists(self.frames)

		s = h * 0.5
		f = 1 / float(self.frames)

		for i in range(self.frames):
			glNewList(self.list + i, GL_COMPILE)
			glBegin(GL_QUADS)
			glTexCoord2f(i * f, 0)
			glVertex2d(-s, -s)
			glTexCoord2f((i + 1) * f, 0)
			glVertex2d(s, -s)
			glTexCoord2f((i + 1) * f, 1)
			glVertex2d(s, s)
			glTexCoord2f(i * f, 1)
			glVertex2d(-s, s)
			glEnd()
			glEndList()

	def draw(self, x, y, r=0, s=1, frame=0):
		glBindTexture(GL_TEXTURE_2D, self.tex)

		glPushMatrix()

		glTranslate(x, y, 0)
		glScale(s, s, 1)
		glRotate(r, 0, 0, 1)
		glCallList(self.list + frame)
		glPopMatrix()


class Engine:

	def __init__(self):

		pygame.display.init()
	#	pygame.display.set_mode((0, 0), pygame.OPENGL | pygame.FULLSCREEN | pygame.DOUBLEBUF)
		pygame.display.set_mode((800, 600), pygame.OPENGL | pygame.DOUBLEBUF)

		pygame.display.set_caption("the beer game, yea!")
		pygame.mouse.set_visible(False)

		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
		glEnable(GL_LINE_SMOOTH)
		glEnable(GL_BLEND)
		glEnable(GL_ALPHA_TEST)
		glEnable(GL_TEXTURE_2D)

		glClearColor(0.2, 0.2, 0.2, 0.2)

		glMatrixMode(GL_PROJECTION)
		glLoadIdentity()
		gluOrtho2D(-400, 400, -300, 300)
		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity()

		pygame.mixer.init()

		self.keys = {}
		self.running = True

	def handle_events(self):
		for event in pygame.event.get():
			if event.type == pygame.QUIT: self.running = False
			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE: self.running = False
				self.keys[event.key] = 1
			elif event.type == pygame.KEYUP:
				self.keys[event.key] = 0

	def keystate(self, key, kill=False):
		if type(key) == str: key = ord(key)
		c = self.keys.get(key, 0)
		if kill: self.keys[key] = 0
		return c



class Main:
	def __init__(self):
		global engine, level, mario
		engine = Engine()

		font.init()

		self.bam_sound = pygame.mixer.Sound("bam.wav")
		self.select_sound = pygame.mixer.Sound("select.wav")
		self.collect_sound = pygame.mixer.Sound("collect.wav")

		self.bottle_sprite = Sprite("bottle.png")
		self.segment_sprite = Sprite("segment.png")
		self.head_sprite = Sprite("head.png")

		self.state = 0
		self.ticks = 0

	def start_values(self):

		self.set_bottle()
		self.segments = []
		self.worm_x = 0
		self.worm_y = 0
		self.worm_dir = 0

		self.speed = 3
		self.length = 20

		self.score = 0


	def set_bottle(self):
		self.bottle_x = random.randint(-380, 380)
		self.bottle_y = random.randint(-280, 280)


	def end_screen(self):

		glColor(1, 1, 1)

		glPushMatrix()
		glLoadIdentity()
		glScale(4, 4, 1)
		center(0, 30, "Game Over")
		glPopMatrix()

		if self.score == 1: center(0, 0, "You drank %d bottle." % self.score)
		else: center(0, 0, "You drank %d bottles." % self.score)
		if self.score >= 20: center(0, -40, "Not too bad.")
		center(0, -100, "Press SPACE.")

		if engine.keystate(K_SPACE, True):
			self.select_sound.play()
			self.start_values()
			self.state = 0


	def splash_screen(self):

		glColor(0.5, math.sin(self.ticks * 0.1) + 0.5 , 0.5)

		glPushMatrix()
		glLoadIdentity()
		glScale(4, 4, 1)
		center(math.sin(self.ticks * 0.03) * 10, 30, "Beer Snake")
		glPopMatrix()

		glColor(1, 1, 1)
		center(0, 0, "Collect as manny bottes as you can!")
		center(0, -40, "Get hammered, but don't hurt your head.")
		center(0, -100, "Press SPACE to start.")
		center(0, -140, "Press ESC to exit.")

		if engine.keystate(K_SPACE, True):
			self.select_sound.play()
			self.start_values()
			self.state = 1


	def in_game_screen(self):

		# drunkenness
		self.worm_dir += math.sin(self.ticks * 0.2 ) * 0.004 * self.score

		self.worm_dir += (engine.keystate(K_RIGHT) - engine.keystate(K_LEFT)) * 0.1
		dx = math.sin(self.worm_dir) * self.speed
		dy = math.cos(self.worm_dir) * self.speed
		self.worm_x += dx
		self.worm_y += dy
		self.segments = [(self.worm_x, self.worm_y)] + self.segments[:self.length]

		# collision
		collision = False
		if abs(self.worm_x) > 384 or abs(self.worm_y) > 284:
			collision = True

		for x, y in self.segments[25:]:
			dx = x - self.worm_x
			dy = y - self.worm_y
			if dx * dx + dy * dy < 780:
				collision = True
				break

		if collision:
			print "Ouch!"
			self.bam_sound.play()
			self.state = 2

		dx = self.bottle_x - self.worm_x
		dy = self.bottle_y - self.worm_y
		if dx * dx + dy * dy < 1200:
			self.collect_sound.play()
			self.score += 1
			self.speed += 0.05
			self.length += 20
			self.set_bottle()


		glColor(1, 1, 1)
		self.bottle_sprite.draw(self.bottle_x, self.bottle_y, math.sin(self.ticks * 0.1) * 10, 1)

		glColor(0, 0.7, 0)
		for x, y in self.segments[4:]: self.segment_sprite.draw(x, y)

		self.head_sprite.draw(self.worm_x, self.worm_y, self.worm_dir * -180 / math.pi, 0.6, (self.ticks/15) % 2)

		glColor(1, 1, 1, 0.5)
		font.put(-380, -280, "bottles: %2d" % self.score)

	def start(self):
		while engine.running:

			engine.handle_events()
			self.ticks += 1
			glClear(GL_COLOR_BUFFER_BIT)

			# splash screen		
			if self.state == 0:	self.splash_screen()
			elif self.state == 1: self.in_game_screen()
			elif self.state == 2: self.end_screen()

			pygame.display.flip()
			pygame.time.wait(15)



if __name__ == "__main__":
	global main
	main = Main()
	main.start()
	print "Remember: don't drink and drive. :)"


