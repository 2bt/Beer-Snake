
from OpenGL.GL import *
from OpenGL.GLU import *
import pygame
from pygame.locals import *


class	Font:
	def __init__(self):
		img = pygame.image.load('font.png')
		w, h = img.get_size()

		img = pygame.transform.scale(img, (w, h))
		data = pygame.image.tostring(img, "RGBA", True)

		self.tex = glGenTextures(1)
		glBindTexture(GL_TEXTURE_2D, self.tex)
		glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

		scale_x = 8.0 / w
		scale_y = 8.0 / h

		self.chars = glGenLists(128)
		for i in range(128):
			glNewList(self.chars + i, GL_COMPILE)
			i -= 32
			if i >= 0 and i < 96:

				a, b = divmod(i, 8)
				tx = scale_x * b
				ty = scale_y * (11 - a)

				glBegin(GL_QUADS)
				glTexCoord2f(tx, ty)
				glVertex2d(-8, -8)
				glTexCoord2f(tx + scale_x, ty)
				glVertex2d(8, -8)
				glTexCoord2f(tx + scale_x, ty + scale_y)
				glVertex2d(8, 8)
				glTexCoord2f(tx, ty + scale_y)
				glVertex2d(-8, 8)
				glEnd()

			glTranslate(16, 0, 0)
			glEndList()

	def put(self, x, y, string):

		glPushMatrix()

		glBindTexture(GL_TEXTURE_2D, self.tex)
		glTranslate(x, y, 0)
		glListBase(self.chars)
		glCallLists(string)

		glPopMatrix()

def init():
	global font
	font = Font()

def put(x, y, string):
	global font
	font.put(x, y, string)

