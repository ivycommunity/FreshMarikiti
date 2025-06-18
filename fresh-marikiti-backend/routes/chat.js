const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const { auth } = require('../middleware/auth');
const { formatResponse, getPaginationParams, buildSortObject } = require('../utils/helpers');

// @route   GET /api/chat/conversations
// @desc    Get user's chat conversations
// @access  Private
router.get('/conversations', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    
    const conversations = await Chat.find({
      participants: req.user.id
    })
    .populate('participants', 'name profilePicture role')
    .populate('lastMessage.sender', 'name')
    .sort({ updatedAt: -1 })
    .skip(skip)
    .limit(limit);

    // Mark conversations as read where current user is not the sender of last message
    const conversationIds = conversations
      .filter(conv => conv.lastMessage && conv.lastMessage.sender.toString() !== req.user.id)
      .map(conv => conv._id);

    if (conversationIds.length > 0) {
      await Chat.updateMany(
        { 
          _id: { $in: conversationIds },
          'messages.readBy': { $ne: req.user.id }
        },
        { $addToSet: { 'messages.$[elem].readBy': req.user.id } },
        { arrayFilters: [{ 'elem.readBy': { $ne: req.user.id } }] }
      );
    }

    const totalConversations = await Chat.countDocuments({
      participants: req.user.id
    });

    res.json(formatResponse(true, {
      conversations,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalConversations / limit),
        totalConversations
      }
    }, 'Conversations retrieved successfully'));
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/chat/:conversationId
// @desc    Get chat messages
// @access  Private
router.get('/:conversationId', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    
    const conversation = await Chat.findById(req.params.conversationId)
      .populate('participants', 'name profilePicture role')
      .populate('messages.sender', 'name profilePicture');

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    // Check if user is participant
    if (!conversation.participants.some(p => p._id.toString() === req.user.id)) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    // Get paginated messages
    const messages = conversation.messages
      .slice(skip, skip + limit)
      .reverse(); // Most recent first

    // Mark messages as read
    await Chat.findByIdAndUpdate(
      req.params.conversationId,
      { $addToSet: { 'messages.$[elem].readBy': req.user.id } },
      { arrayFilters: [{ 'elem.readBy': { $ne: req.user.id } }] }
    );

    res.json(formatResponse(true, {
      conversation: {
        _id: conversation._id,
        participants: conversation.participants,
        orderId: conversation.orderId,
        type: conversation.type,
        isActive: conversation.isActive
      },
      messages,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(conversation.messages.length / limit),
        totalMessages: conversation.messages.length
      }
    }, 'Messages retrieved successfully'));
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/chat/start
// @desc    Start a new chat conversation
// @access  Private
router.post('/start', auth, async (req, res) => {
  try {
    const { participantId, orderId, type = 'order_chat' } = req.body;

    if (!participantId) {
      return res.status(400).json(formatResponse(false, null, 'Participant ID is required'));
    }

    // Check if conversation already exists
    let conversation = await Chat.findOne({
      participants: { $all: [req.user.id, participantId] },
      orderId: orderId || { $exists: false }
    }).populate('participants', 'name profilePicture role');

    if (conversation) {
      return res.json(formatResponse(true, conversation, 'Conversation already exists'));
    }

    // Create new conversation
    conversation = new Chat({
      participants: [req.user.id, participantId],
      orderId,
      type,
      isActive: true,
      messages: []
    });

    await conversation.save();

    const populatedConversation = await Chat.findById(conversation._id)
      .populate('participants', 'name profilePicture role');

    res.status(201).json(formatResponse(true, populatedConversation, 'Conversation created successfully'));
  } catch (error) {
    console.error('Error starting conversation:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/chat/:conversationId/message
// @desc    Send a message
// @access  Private
router.post('/:conversationId/message', auth, async (req, res) => {
  try {
    const { content, messageType = 'text', attachments = [] } = req.body;

    if (!content && (!attachments || attachments.length === 0)) {
      return res.status(400).json(formatResponse(false, null, 'Message content or attachments required'));
    }

    const conversation = await Chat.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    const message = {
      sender: req.user.id,
      content,
      messageType,
      attachments,
      timestamp: new Date(),
      readBy: [req.user.id],
      isEdited: false
    };

    conversation.messages.push(message);
    conversation.lastMessage = {
      content,
      sender: req.user.id,
      timestamp: new Date()
    };
    conversation.updatedAt = new Date();

    await conversation.save();

    const populatedConversation = await Chat.findById(conversation._id)
      .populate('participants', 'name profilePicture role')
      .populate('messages.sender', 'name profilePicture');

    const newMessage = populatedConversation.messages[populatedConversation.messages.length - 1];

    res.status(201).json(formatResponse(true, newMessage, 'Message sent successfully'));
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/chat/:conversationId/message/:messageId
// @desc    Edit a message
// @access  Private
router.put('/:conversationId/message/:messageId', auth, async (req, res) => {
  try {
    const { content } = req.body;

    if (!content) {
      return res.status(400).json(formatResponse(false, null, 'Message content is required'));
    }

    const conversation = await Chat.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    const message = conversation.messages.id(req.params.messageId);

    if (!message) {
      return res.status(404).json(formatResponse(false, null, 'Message not found'));
    }

    // Only allow editing own messages
    if (message.sender.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Can only edit your own messages'));
    }

    // Only allow editing within 24 hours
    const hoursSinceMessage = (new Date() - message.timestamp) / (1000 * 60 * 60);
    if (hoursSinceMessage > 24) {
      return res.status(400).json(formatResponse(false, null, 'Cannot edit messages older than 24 hours'));
    }

    message.content = content;
    message.isEdited = true;
    message.editedAt = new Date();

    await conversation.save();

    res.json(formatResponse(true, message, 'Message edited successfully'));
  } catch (error) {
    console.error('Error editing message:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   DELETE /api/chat/:conversationId/message/:messageId
// @desc    Delete a message
// @access  Private
router.delete('/:conversationId/message/:messageId', auth, async (req, res) => {
  try {
    const conversation = await Chat.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    const message = conversation.messages.id(req.params.messageId);

    if (!message) {
      return res.status(404).json(formatResponse(false, null, 'Message not found'));
    }

    // Only allow deleting own messages
    if (message.sender.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Can only delete your own messages'));
    }

    message.remove();
    await conversation.save();

    res.json(formatResponse(true, null, 'Message deleted successfully'));
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/chat/:conversationId/mark-read
// @desc    Mark conversation as read
// @access  Private
router.post('/:conversationId/mark-read', auth, async (req, res) => {
  try {
    const conversation = await Chat.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    // Mark all messages as read by this user
    await Chat.findByIdAndUpdate(
      req.params.conversationId,
      { $addToSet: { 'messages.$[].readBy': req.user.id } }
    );

    res.json(formatResponse(true, null, 'Conversation marked as read'));
  } catch (error) {
    console.error('Error marking conversation as read:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/chat/unread-count
// @desc    Get unread messages count
// @access  Private
router.get('/unread-count', auth, async (req, res) => {
  try {
    const conversations = await Chat.find({
      participants: req.user.id,
      'messages.readBy': { $ne: req.user.id }
    });

    let unreadCount = 0;
    conversations.forEach(conversation => {
      conversation.messages.forEach(message => {
        if (!message.readBy.includes(req.user.id) && message.sender.toString() !== req.user.id) {
          unreadCount++;
        }
      });
    });

    res.json(formatResponse(true, { unreadCount }, 'Unread count retrieved successfully'));
  } catch (error) {
    console.error('Error getting unread count:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/chat/:conversationId/close
// @desc    Close a conversation
// @access  Private
router.post('/:conversationId/close', auth, async (req, res) => {
  try {
    const conversation = await Chat.findById(req.params.conversationId);

    if (!conversation) {
      return res.status(404).json(formatResponse(false, null, 'Conversation not found'));
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    conversation.isActive = false;
    conversation.closedAt = new Date();
    conversation.closedBy = req.user.id;

    await conversation.save();

    res.json(formatResponse(true, conversation, 'Conversation closed successfully'));
  } catch (error) {
    console.error('Error closing conversation:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

module.exports = router; 