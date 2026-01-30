import unittest

from message import Message, Message_Type

class TestSerialization(unittest.TestCase):

    # Equality of Message and Serialize(Deserialize(Message))

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

    # Length

    def test_length_0bytes(self):
        p = Message(Message_Type.REQUEST_OPEN)
        self.assertEqual(len(p.content), 0)

    def test_length_32byte(self):
        p = Message(Message_Type.CHALLENGE)
        self.assertEqual(len(p.content), 32)

if __name__ == "__main__":
    unittest.main()
