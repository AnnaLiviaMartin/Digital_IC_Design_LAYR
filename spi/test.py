import unittest

from message import Message, Message_Type

class TestSerialization(unittest.TestCase):

    def test_open(self):
        p = Message(Message_Type.REQUEST_OPEN)
        self.assertEqual(p, Message.deserialize(p.serialize()))

    def test_challenge(self):
        p = Message(Message_Type.CHALLENGE, b'SomeRandomNumber')
        self.assertEqual(p, Message.deserialize(p.serialize()))

    def test_challenge_answer(self):
        p = Message(Message_Type.CHALLENGE_ANSWER, b'SomeHash')
        self.assertEqual(p, Message.deserialize(p.serialize()))

    def test_grant_access(self):
        p = Message(Message_Type.GRANT_ACCESS)
        self.assertEqual(p, Message.deserialize(p.serialize()))

    def test_deny_access(self):
        p = Message(Message_Type.DENY_ACCESS)
        self.assertEqual(p, Message.deserialize(p.serialize()))

    def test_error(self):
        p = Message(Message_Type.ERROR)
        self.assertEqual(p, Message.deserialize(p.serialize()))

if __name__ == "__main__":
    unittest.main()
